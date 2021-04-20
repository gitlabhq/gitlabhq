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

      UnboundedSearch = Class.new(StandardError)

      included do
        after_create :sync_traversal_ids, if: -> { sync_traversal_ids? }
        after_update :sync_traversal_ids, if: -> { sync_traversal_ids? && saved_change_to_parent_id? }

        scope :traversal_ids_contains, ->(ids) { where("traversal_ids @> (?)", ids) }
      end

      def sync_traversal_ids?
        Feature.enabled?(:sync_traversal_ids, root_ancestor, default_enabled: :yaml)
      end

      def use_traversal_ids?
        Feature.enabled?(:use_traversal_ids, root_ancestor, default_enabled: :yaml)
      end

      def self_and_descendants
        if use_traversal_ids?
          lineage(self)
        else
          super
        end
      end

      private

      # Update the traversal_ids for the full hierarchy.
      #
      # NOTE: self.traversal_ids will be stale. Reload for a fresh record.
      def sync_traversal_ids
        # Clear any previously memoized root_ancestor as our ancestors have changed.
        clear_memoization(:root_ancestor)

        Namespace::TraversalHierarchy.for_namespace(root_ancestor).sync_traversal_ids!
      end

      # Make sure we drop the STI `type = 'Group'` condition for better performance.
      # Logically equivalent so long as hierarchies remain homogeneous.
      def without_sti_condition
        self.class.unscope(where: :type)
      end

      # Search this namespace's lineage. Bound inclusively by top node.
      def lineage(top)
        raise UnboundedSearch.new('Must bound search by a top') unless top

        without_sti_condition
          .traversal_ids_contains("{#{top.id}}")
      end
    end
  end
end
