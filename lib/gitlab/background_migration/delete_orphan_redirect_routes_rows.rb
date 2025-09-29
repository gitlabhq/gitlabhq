# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteOrphanRedirectRoutesRows < BatchedMigrationJob
      operation_name :delete_orphan_redirect_routes_rows
      feature_category :groups_and_projects
      # rubocop:disable Database/AvoidScopeTo -- supporting index: tmp_idx_redirect_routes_on_source_type_id_where_namespace_null
      scope_to ->(relation) { relation.where(source_type: 'Project', namespace_id: nil) }
      # rubocop:enable Database/AvoidScopeTo

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('LEFT OUTER JOIN projects ON redirect_routes.source_id = projects.id')
            .where(projects: { id: nil })
            .delete_all
        end
      end
    end
  end
end
