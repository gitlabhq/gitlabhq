# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Back-fills the `issues.namespace_id` by setting it to corresponding project.project_namespace_id
    class BackfillProjectNamespaceOnIssues < BatchedMigrationJob
      def perform
        each_sub_batch(
          operation_name: :update_all,
          batching_scope: -> (relation) {
            relation.joins("INNER JOIN projects ON projects.id = issues.project_id")
              .select("issues.id AS issue_id, projects.project_namespace_id").where(issues: { namespace_id: nil })
          }
        ) do |sub_batch|
          connection.execute <<~SQL
            UPDATE issues
            SET namespace_id = projects.project_namespace_id
            FROM (#{sub_batch.to_sql}) AS projects(issue_id, project_namespace_id)
            WHERE issues.id = issue_id
          SQL
        end
      end
    end
  end
end
