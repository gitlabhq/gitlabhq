# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # backfills project_ci_cd_settings
    class BackfillMissingCiCdSettings < BatchedMigrationJob
      # migrations only version of `project_ci_cd_settings` table
      class ProjectCiCdSetting < ::ApplicationRecord
        self.table_name = 'project_ci_cd_settings'
      end

      operation_name :backfill_missing_ci_cd_settings
      feature_category :source_code_management

      def perform
        each_sub_batch do |sub_batch|
          sub_batch = sub_batch.where(%{
            NOT EXISTS (
              SELECT 1
              FROM project_ci_cd_settings
              WHERE project_ci_cd_settings.project_id = projects.id
            )
          })
          next unless sub_batch.present?

          ci_cd_attributes = sub_batch.map do |project|
            {
              project_id: project.id,
              default_git_depth: 20,
              forward_deployment_enabled: true
            }
          end

          ProjectCiCdSetting.insert_all(ci_cd_attributes)
        end
      end
    end
  end
end
