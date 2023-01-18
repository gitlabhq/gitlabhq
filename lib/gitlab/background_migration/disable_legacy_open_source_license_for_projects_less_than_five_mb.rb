# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for projects less than 5 MB
    class DisableLegacyOpenSourceLicenseForProjectsLessThanFiveMb < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      scope_to ->(relation) do
        relation
          .where(legacy_open_source_license_available: true)
      end

      operation_name :disable_legacy_open_source_license_for_projects_less_than_five_mb
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          updates = { legacy_open_source_license_available: false, updated_at: Time.current }

          sub_batch
            .joins('INNER JOIN project_statistics ON project_statistics.project_id = project_settings.project_id')
            .where('project_statistics.repository_size < ?', 5.megabyte)
            .update_all(updates)
        end
      end
    end
  end
end
