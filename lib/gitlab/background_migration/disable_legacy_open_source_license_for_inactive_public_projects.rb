# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for inactive, public projects
    class DisableLegacyOpenSourceLicenseForInactivePublicProjects <
        ::Gitlab::BackgroundMigration::BatchedMigrationJob
      PUBLIC = 20
      LAST_ACTIVITY_DATE = '2021-07-01'

      operation_name :disable_legacy_open_source_license_available
      feature_category :database

      # Migration only version of `project_settings` table
      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch(
          batching_scope: ->(relation) {
            relation.where(visibility_level: PUBLIC).where('last_activity_at < ?', LAST_ACTIVITY_DATE)
          }
        ) do |sub_batch|
          ProjectSetting.where(project_id: sub_batch).update_all(legacy_open_source_license_available: false)
        end
      end
    end
  end
end
