# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPoolRepositoriesOrganizationId < BatchedMigrationJob
      operation_name :backfill_pool_repositories_organization_id

      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          # Case 1: source_project_id is set, get organization from source project (PREFERRED)
          connection.exec_update(update_from_source_project_sql(sub_batch))

          # Case 2: source_project_id is empty, but we can detect organization
          # through the member_projects (projects.pool_repository_id relation)
          connection.exec_update(update_from_member_projects_sql(sub_batch))

          # Case 3: No sharding key can be determined - assign default organization_id = 1
          connection.exec_update(update_with_default_organization_sql(sub_batch))
        end
      end

      private

      def update_from_source_project_sql(sub_batch)
        <<~SQL
          UPDATE pool_repositories
          SET organization_id = projects.organization_id
          FROM projects
          WHERE pool_repositories.source_project_id = projects.id
          AND pool_repositories.organization_id IS NULL
          AND pool_repositories.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end

      def update_from_member_projects_sql(sub_batch)
        <<~SQL
          UPDATE pool_repositories
          SET organization_id = subquery.organization_id
          FROM (
            SELECT DISTINCT p.pool_repository_id, p.organization_id
            FROM projects p
            WHERE p.pool_repository_id IS NOT NULL
          ) AS subquery
          WHERE pool_repositories.id = subquery.pool_repository_id
          AND pool_repositories.organization_id IS NULL
          AND pool_repositories.source_project_id IS NULL
          AND pool_repositories.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end

      def update_with_default_organization_sql(sub_batch)
        <<~SQL
          UPDATE pool_repositories
          SET organization_id = 1
          WHERE pool_repositories.organization_id IS NULL
          AND pool_repositories.id IN (#{sub_batch.select(:id).to_sql})
        SQL
      end
    end
  end
end
