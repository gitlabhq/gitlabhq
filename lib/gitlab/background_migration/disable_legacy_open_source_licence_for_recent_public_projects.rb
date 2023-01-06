# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for public projects created after 17/02/2022
    class DisableLegacyOpenSourceLicenceForRecentPublicProjects < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      PUBLIC = 20
      THRESHOLD_DATE = '2022-02-17 09:00:00'

      operation_name :disable_legacy_open_source_licence_for_recent_public_projects
      feature_category :database

      # Migration only version of `project_settings` table
      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch(
          batching_scope: ->(relation) {
            relation.where(visibility_level: PUBLIC).where('created_at >= ?', THRESHOLD_DATE)
          }
        ) do |sub_batch|
          ProjectSetting.where(project_id: sub_batch)
                        .where(legacy_open_source_license_available: true)
                        .update_all(legacy_open_source_license_available: false)
        end
      end
    end
  end
end
