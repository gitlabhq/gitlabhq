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
        column_name = if skope == Namespace
                        :self_and_descendant_ids
                      elsif skope == self.class
                        # Group_ids is a bit misleading because skope can be ProjectNamespace too.
                        :self_and_descendant_group_ids
                      end

        return super unless column_name

        scope_with_cached_ids(
          super,
          skope,
          Namespaces::Descendants.arel_table[column_name]
        )
      end

      override :all_project_ids
      def all_project_ids
        scope_with_cached_ids(
          all_projects.select(:id),
          Project,
          Namespaces::Descendants.arel_table[:all_project_ids]
        )
      end

      override :all_unarchived_project_ids
      def all_unarchived_project_ids
        scope_with_cached_ids(
          all_projects.self_and_ancestors_non_archived.select(:id),
          Project,
          Namespaces::Descendants.arel_table[:all_unarchived_project_ids]
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
