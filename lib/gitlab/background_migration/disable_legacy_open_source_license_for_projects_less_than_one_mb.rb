# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for projects less than 1 MB
    class DisableLegacyOpenSourceLicenseForProjectsLessThanOneMb < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) { relation.where(legacy_open_source_license_available: true) }
      operation_name :disable_legacy_open_source_license_for_projects_less_than_one_mb
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          updates = { legacy_open_source_license_available: false, updated_at: Time.current }

          sub_batch
            .joins('INNER JOIN project_statistics ON project_statistics.project_id = project_settings.project_id')
            .where('project_statistics.repository_size < ?', 1.megabyte)
            .update_all(updates)
        end
      end
    end
  end
end
