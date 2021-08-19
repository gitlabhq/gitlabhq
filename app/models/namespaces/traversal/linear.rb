# frozen_string_literal: true
#
# Query a recursively defined namespace hierarchy using linear methods through
# the traversal_ids attribute.
#
# Namespace is a nested hierarchy of one parent to many children. A search
# using only the parent-child relationships is a slow operation. This process
# was previously optimized using Postgresql recursive common table expressions
# (CTE) with acceptable performance. However, it lead to slower than possible
# performance, and resulted in complicated queries that were difficult to make
# performant.
#
# Instead of searching the hierarchy recursively, we store a `traversal_ids`
# attribute on each node. The `traversal_ids` is an ordered array of Namespace
# IDs that define the traversal path from the root Namespace to the current
# Namespace.
#
# For example, suppose we have the following Namespaces:
#
# GitLab (id: 1) > Engineering (id: 2) > Manage (id: 3) > Access (id: 4)
#
# Then `traversal_ids` for group "Access" is [1, 2, 3, 4]
#
# And we can match against other Namespace `traversal_ids` such that:
#
# - Ancestors are [1], [1, 2], [1, 2, 3]
# - Descendants are [1, 2, 3, 4, *]
# - Root is [1]
# - Hierarchy is [1, *]
#
# Note that this search method works so long as the IDs are unique and the
# traversal path is ordered from root to leaf nodes.
#
# We implement this in the database using Postgresql arrays, indexed by a
# generalized inverted index (gin).
module Namespaces
  module Traversal
    module Linear
      extend ActiveSupport::Concern
      include LinearScopes

      UnboundedSearch = Class.new(StandardError)

      included do
        before_update :lock_both_roots, if: -> { sync_traversal_ids? && parent_id_changed? }
        after_create :sync_traversal_ids, if: -> { sync_traversal_ids? }
        after_update :sync_traversal_ids, if: -> { sync_traversal_ids? && saved_change_to_parent_id? }
      end

      def sync_traversal_ids?
        Feature.enabled?(:sync_traversal_ids, root_ancestor, default_enabled: :yaml)
      end

      def use_traversal_ids?
        return false unless Feature.enabled?(:use_traversal_ids, default_enabled: :yaml)

        traversal_ids.present?
      end

      def use_traversal_ids_for_ancestors?
        return false unless use_traversal_ids?
        return false unless Feature.enabled?(:use_traversal_ids_for_ancestors, root_ancestor, default_enabled: :yaml)

        traversal_ids.present?
      end

      def use_traversal_ids_for_root_ancestor?
        return false unless Feature.enabled?(:use_traversal_ids_for_root_ancestor, default_enabled: :yaml)

        traversal_ids.present?
      end

      def root_ancestor
        return super unless use_traversal_ids_for_root_ancestor?

        strong_memoize(:root_ancestor) do
          if parent.nil?
            self
          else
            Namespace.find_by(id: traversal_ids.first)
          end
        end
      end

      def self_and_descendants
        return super unless use_traversal_ids?

        lineage(top: self)
      end

      def self_and_descendant_ids
        return super unless use_traversal_ids?

        self_and_descendants.as_ids
      end

      def descendants
        return super unless use_traversal_ids?

        self_and_descendants.where.not(id: id)
      end

      def ancestors(hierarchy_order: nil)
        return super unless use_traversal_ids_for_ancestors?

        return self.class.none if parent_id.blank?

        lineage(bottom: parent, hierarchy_order: hierarchy_order)
      end

      def ancestor_ids(hierarchy_order: nil)
        return super unless use_traversal_ids_for_ancestors?

        hierarchy_order == :desc ? traversal_ids[0..-2] : traversal_ids[0..-2].reverse
      end

      def self_and_ancestors(hierarchy_order: nil)
        return super unless use_traversal_ids_for_ancestors?

        return self.class.where(id: id) if parent_id.blank?

        lineage(bottom: self, hierarchy_order: hierarchy_order)
      end

      def self_and_ancestor_ids(hierarchy_order: nil)
        return super unless use_traversal_ids_for_ancestors?

        hierarchy_order == :desc ? traversal_ids : traversal_ids.reverse
      end

      private

      # Update the traversal_ids for the full hierarchy.
      #
      # NOTE: self.traversal_ids will be stale. Reload for a fresh record.
      def sync_traversal_ids
        # Clear any previously memoized root_ancestor as our ancestors have changed.
        clear_memoization(:root_ancestor)

        Namespace::TraversalHierarchy.for_namespace(self).sync_traversal_ids!
      end

      # Lock the root of the hierarchy we just left, and lock the root of the hierarchy
      # we just joined. In most cases the two hierarchies will be the same.
      def lock_both_roots
        parent_ids = [
          parent_id_was || self.id,
          parent_id || self.id
        ].compact

        roots = Gitlab::ObjectHierarchy
          .new(Namespace.where(id: parent_ids))
          .base_and_ancestors
          .reorder(nil)
          .where(parent_id: nil)

        Namespace.lock.select(:id).where(id: roots).order(id: :asc).load
      end

      # Search this namespace's lineage. Bound inclusively by top node.
      def lineage(top: nil, bottom: nil, hierarchy_order: nil)
        raise UnboundedSearch, 'Must bound search by either top or bottom' unless top || bottom

        skope = self.class.without_sti_condition

        if top
          skope = skope.where("traversal_ids @> ('{?}')", top.id)
        end

        if bottom
          skope = skope.where(id: bottom.traversal_ids[0..-1])
        end

        # The original `with_depth` attribute in ObjectHierarchy increments as you
        # walk away from the "base" namespace. This direction changes depending on
        # if you are walking up the ancestors or down the descendants.
        if hierarchy_order
          depth_sql = "ABS(#{traversal_ids.count} - array_length(traversal_ids, 1))"
          skope = skope.select(skope.arel_table[Arel.star], "#{depth_sql} as depth")
          # The SELECT includes an extra depth attribute. We wrap the SQL in a
          # standard SELECT to avoid mismatched attribute errors when trying to
          # chain future ActiveRelation commands, and retain the ordering.
          skope = self.class
            .without_sti_condition
            .from(skope, self.class.table_name)
            .order(depth: hierarchy_order)
        end

        skope
      end
    end
  end
end
