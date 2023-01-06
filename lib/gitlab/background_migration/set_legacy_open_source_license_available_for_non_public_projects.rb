# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for non-public projects
    class SetLegacyOpenSourceLicenseAvailableForNonPublicProjects < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      PUBLIC = 20

      operation_name :set_legacy_open_source_license_available
      feature_category :database

      # Migration only version of `project_settings` table
      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch(
          batching_scope: ->(relation) { relation.where.not(visibility_level: PUBLIC) }
        ) do |sub_batch|
          ProjectSetting.where(project_id: sub_batch).update_all(legacy_open_source_license_available: false)
        end
      end
    end
  end
end
