# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillProjectsRedirectRoutesNamespaceId < BatchedMigrationJob
      operation_name :backfill_projects_redirect_routes_namespace_id
      feature_category :groups_and_projects

      scope_to ->(relation) do
        relation
          .joins('inner join projects on redirect_routes.source_id = projects.id')
          .where(source_type: 'Project', namespace_id: nil)
          .select(:id, 'projects.project_namespace_id')
      end

      def perform
        each_sub_batch do |sub_batch|
          connection.execute(<<~SQL)
            WITH batched_relation AS (#{sub_batch.to_sql})
            UPDATE redirect_routes
            SET namespace_id = batched_relation.project_namespace_id
            FROM batched_relation
            WHERE redirect_routes.id = batched_relation.id
          SQL
        end
      end
    end
  end
end
