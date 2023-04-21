# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Backfill design_management_repositories table for a range of projects
    class BackfillDesignManagementRepositories < BatchedMigrationJob
      operation_name :backfill_design_management_repositories
      feature_category :geo_replication

      def perform
        each_sub_batch do |sub_batch|
          backfill_design_management_repositories(sub_batch)
        end
      end

      def backfill_design_management_repositories(relation)
        connection.execute(
          <<~SQL
          INSERT INTO design_management_repositories (project_id, created_at, updated_at)
            SELECT projects.id, now(), now()
            FROM projects
            WHERE projects.id IN(#{relation.select(:id).to_sql})
          ON CONFLICT (project_id) DO NOTHING;
        SQL
        )
      end
    end
  end
end
