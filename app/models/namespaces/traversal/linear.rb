# frozen_string_literal: true
#
# Query a recursively defined namespace hierarchy using linear methods through
# the traversal_ids attribute.
#
# Namespace is a nested hierarchy of one parent to many children. A search
# using only the parent-child relationships is a slow operation. This process
# was previously optimized using PostgreSQL recursive common table expressions
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
# We implement this in the database using PostgreSQL arrays, indexed by a
# generalized inverted index (gin).
module Namespaces
  module Traversal
    module Linear
      extend ActiveSupport::Concern
      include LinearScopes

      UnboundedSearch = Class.new(StandardError)

      included do
        before_update :lock_both_roots, if: -> { parent_id_changed? }
        after_update :sync_traversal_ids, if: -> { saved_change_to_parent_id? }

        # Update the traversal_ids for this namespace in a process safe way.
        #
        # This uses rails internal before_commit API to sync traversal_ids on namespace create, right before transaction is committed.
        # This helps reduce the time during which the root namespace record is locked to ensure updated traversal_ids are valid
        before_commit :sync_traversal_ids, if: -> { Feature.disabled?(:shared_namespace_locks, root_ancestor) }, on: [:create]
        # We are taking less aggressive shared locks here so we do not have to use the unofficial before_commit API.
        # The before_commit behaves in unexpected ways for something like:
        # build(:issue, spam: true).project.update_attributes(:visibility_level, Gitlab::VisibilityLevel::PUBLIC)
        after_create :sync_traversal_ids_on_create, -> { Feature.enabled?(:shared_namespace_locks, root_ancestor) }

        after_commit :set_traversal_ids,
          if: -> { traversal_ids.empty? || saved_change_to_parent_id? },
          on: [:create, :update]

        define_model_callbacks :sync_traversal_ids
      end

      class_methods do
        # This method looks into a list of namespaces trying to optimize a returned traversal_ids
        # into a list of shortest prefixes, due to fact that the shortest prefixes include all children.
        # Example:
        # INPUT: [[4909902], [4909902,51065789], [4909902,51065793], [7135830], [15599674, 1], [15599674, 1, 3], [15599674, 2]]
        # RESULT: [[4909902], [7135830], [15599674, 1], [15599674, 2]]
        def shortest_traversal_ids_prefixes
          prefixes = []

          # The array needs to be sorted (O(nlogn)) to ensure shortest elements are always first
          # This allows to do O(n) search of shortest prefixes
          all_traversal_ids = all.order('namespaces.traversal_ids').pluck('namespaces.traversal_ids')
          last_prefix = [nil]

          all_traversal_ids.each do |traversal_ids|
            next if last_prefix == traversal_ids[0..(last_prefix.count - 1)]

            last_prefix = traversal_ids
            prefixes << traversal_ids
          end

          prefixes
        end
      end

      def traversal_path
        "#{traversal_ids.join('/')}/"
      end

      def use_traversal_ids?
        traversal_ids.present?
      end

      # Return the top most ancestor of this namespace.
      # This method aims to minimize the number of queries by trying to re-use data that has already been loaded.
      def root_ancestor
        strong_memoize(:root_ancestor) do
          if parent_loaded_and_present?
            parent.root_ancestor
          elsif parent_id_present_and_traversal_ids_empty?
            # Parent is in the database, so find our root ancestor using our parent's traversal_ids.
            parent = Namespace.where(id: parent_id).select(:traversal_ids)
            Namespace.from("(#{parent.to_sql}) AS parent_namespace, namespaces")
                     .find_by('namespaces.id = parent_namespace.traversal_ids[1]')
          elsif parent_id.nil?
            # There is no parent, so we are the root ancestor.
            self
          else
            Namespace.find_by(id: traversal_ids.first)
          end
        end
      end

      def all_project_ids
        all_projects.select(:id)
      end

      def self_and_descendants(skope: self.class)
        return super unless use_traversal_ids?

        lineage(top: self, skope: skope)
      end

      def self_and_descendant_ids(skope: self.class)
        return super unless use_traversal_ids?

        self_and_descendants(skope: skope).as_ids
      end

      def descendants
        return super unless use_traversal_ids?

        self_and_descendants.where.not(id: id)
      end

      def self_and_hierarchy
        return super unless use_traversal_ids?

        self_and_descendants.or(ancestors)
      end

      def ancestors(hierarchy_order: nil)
        return super unless use_traversal_ids?

        return self.class.none if parent_id.blank?

        lineage(bottom: parent, hierarchy_order: hierarchy_order)
      end

      def ancestor_ids(hierarchy_order: nil)
        return super unless use_traversal_ids?

        hierarchy_order == :desc ? traversal_ids[0..-2] : traversal_ids[0..-2].reverse
      end

      # Returns all ancestors up to but excluding the top.
      # When no top is given, all ancestors are returned.
      # When top is not found, returns all ancestors.
      #
      # This copies the behavior of the recursive method. We will deprecate
      # this behavior soon.
      def ancestors_upto(top = nil, hierarchy_order: nil)
        return super unless use_traversal_ids?

        # We can't use a default value in the method definition above because
        # we need to preserve those specific parameters for super.
        hierarchy_order ||= :desc

        top_index = ancestors_upto_top_index(top)
        ids = traversal_ids[top_index...-1].reverse

        # WITH ORDINALITY lets us order the result to match traversal_ids order.
        ids_string = ids.map { |id| Integer(id) }.join(',')
        from_sql = <<~SQL
          unnest(ARRAY[#{ids_string}]::bigint[]) WITH ORDINALITY AS ancestors(id, ord)
          INNER JOIN namespaces ON namespaces.id = ancestors.id
        SQL

        self.class
          .from(Arel.sql(from_sql))
          .order('ancestors.ord': hierarchy_order)
      end

      def self_and_ancestors(hierarchy_order: nil)
        return super unless use_traversal_ids?

        return self.class.where(id: id) if parent_id.blank?

        lineage(bottom: self, hierarchy_order: hierarchy_order)
      end

      def self_and_ancestor_ids(hierarchy_order: nil)
        return super unless use_traversal_ids?

        hierarchy_order == :desc ? traversal_ids : traversal_ids.reverse
      end

      def parent=(obj)
        super(obj)
        set_traversal_ids
      end

      def parent_id=(id)
        super(id)
        set_traversal_ids
      end

      private

      # Update the traversal_ids for the full hierarchy.
      #
      # NOTE: self.traversal_ids will be stale. Reload for a fresh record.
      def sync_traversal_ids
        run_callbacks :sync_traversal_ids do
          # Clear any previously memoized root_ancestor as our ancestors have changed.
          clear_memoization(:root_ancestor)

          Namespace::TraversalHierarchy.for_namespace(self).sync_traversal_ids!
        end
      end

      def sync_traversal_ids_on_create
        run_callbacks :sync_traversal_ids do
          # Clear any previously memoized root_ancestor as our ancestors have changed.
          clear_memoization(:root_ancestor)

          # When the FF is enabled we sync the traversal ids from the node itself. In this case the ancestors are locked
          # FOR SHARE while the node is locked with FOR NO KEY UPDATE.
          # When the FF is diabled we sync the traversal ids from the node's root ancestor which is locked with FOR NO
          # KEY UPDATE.
          if Feature.enabled?(:shared_namespace_locks, root_ancestor)
            Namespace::TraversalHierarchy.sync_traversal_ids!(self)
          else
            Namespace::TraversalHierarchy.for_namespace(self).sync_traversal_ids!
          end
        end
      end

      def set_traversal_ids
        return if id.blank?

        # This is a temporary guard and will be removed.
        return if is_a?(Namespaces::ProjectNamespace)

        # Update our traversal_ids state to match the database.
        self.traversal_ids = self.class.where(id: self).pick(:traversal_ids)
        clear_traversal_ids_change

        clear_memoization(:root_ancestor)

        # Update traversal_ids for any associated child objects.
        children.each(&:reload) if children.loaded?
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
          .top_level

        Namespace.lock('FOR NO KEY UPDATE').select(:id).where(id: roots).order(id: :asc).load
      end

      # Search this namespace's lineage. Bound inclusively by top node.
      def lineage(top: nil, bottom: nil, hierarchy_order: nil, skope: self.class)
        raise UnboundedSearch, 'Must bound search by either top or bottom' unless top || bottom

        if top
          skope = skope.where("traversal_ids @> ('{?}')", top.id)
        end

        if bottom
          skope = skope.where(id: bottom.traversal_ids)
        end

        # The original `with_depth` attribute in ObjectHierarchy increments as you
        # walk away from the "base" namespace. This direction changes depending on
        # if you are walking up the ancestors or down the descendants.
        if hierarchy_order
          depth_sql = "ABS(#{traversal_ids.count} - array_length(traversal_ids, 1))"
          skope = skope.select(skope.default_select_columns, "#{depth_sql} as depth")
          # The SELECT includes an extra depth attribute. We wrap the SQL in a
          # standard SELECT to avoid mismatched attribute errors when trying to
          # chain future ActiveRelation commands, and retain the ordering.
          skope = self.class
            .from(skope, self.class.table_name)
            .select(skope.arel_table[Arel.star])
            .order(depth: hierarchy_order)
        end

        skope
      end

      def ancestors_upto_top_index(top)
        return 0 if top.nil?

        index = traversal_ids.find_index(top.id)
        if index.nil?
          0
        else
          index + 1
        end
      end

      # This case is possible when parent has not been persisted or we're inside a transaction.
      def parent_loaded_and_present?
        association(:parent).loaded? && parent.present?
      end

      # This case occurs when parent is persisted but we are not.
      def parent_id_present_and_traversal_ids_empty?
        parent_id.present? && traversal_ids.empty?
      end
    end
  end
end
