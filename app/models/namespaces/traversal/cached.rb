# frozen_string_literal: true

module Namespaces
  module Traversal
    module Cached
      extend ActiveSupport::Concern
      extend Gitlab::Utils::Override

      included do
        after_destroy :invalidate_descendants_cache
      end

      override :self_and_descendant_ids
      def self_and_descendant_ids(skope: self.class)
        # Cache only works for descendants
        # of the same type as the caller.
        return super unless skope == self.class
        return super unless attempt_to_use_cached_data?

        scope_with_cached_ids(
          super,
          skope,
          Namespaces::Descendants.arel_table[:self_and_descendant_group_ids]
        )
      end

      override :all_project_ids
      def all_project_ids
        return super unless attempt_to_use_cached_data?

        scope_with_cached_ids(
          all_projects.select(:id),
          Project,
          Namespaces::Descendants.arel_table[:all_project_ids]
        )
      end

      private

      # This method implements an OR based cache lookup using COALESCE, similar what you would do in Ruby:
      # return cheap_cached_data || expensive_uncached_data
      def scope_with_cached_ids(consistent_ids_scope, model, cached_ids_column)
        # Look up the cached ids and unnest them into rows if the cache is up to date.
        cache_lookup_query = Namespaces::Descendants
          .where(outdated_at: nil, namespace_id: id)
          .select(cached_ids_column.as('ids'))

        # Invoke the consistent lookup query and collect the ids as a single array value
        consistent_descendant_ids_scope = model
          .from(consistent_ids_scope.arel.as(model.table_name))
          .reselect(Arel::Nodes::NamedFunction.new('ARRAY_AGG', [model.arel_table[:id]]).as('ids'))
          .unscope(where: :type)

        from = <<~SQL
        UNNEST(
          COALESCE(
            (SELECT ids FROM (#{cache_lookup_query.to_sql}) cached_query),
            (SELECT ids FROM (#{consistent_descendant_ids_scope.to_sql}) consistent_query))
        ) AS #{model.table_name}(id)
        SQL

        model
          .from(from)
          .unscope(where: :type)
          .select(:id)
      end

      def attempt_to_use_cached_data?
        Feature.enabled?(:group_hierarchy_optimization, self, type: :beta)
      end

      override :sync_traversal_ids
      def sync_traversal_ids
        super
        wrap_sync_traversal_ids
      end

      override :sync_traversal_ids_on_create
      def sync_traversal_ids_on_create
        super
        wrap_sync_traversal_ids
      end

      def wrap_sync_traversal_ids
        return if is_a?(Namespaces::UserNamespace)

        ids = [id]
        ids.concat((saved_changes[:parent_id] - [parent_id]).compact) if saved_changes[:parent_id]
        Namespaces::Descendants.expire_for(ids)
      end

      def invalidate_descendants_cache
        return if is_a?(Namespaces::UserNamespace)

        Namespaces::Descendants.expire_for([parent_id, id].compact)
      end
    end
  end
end
