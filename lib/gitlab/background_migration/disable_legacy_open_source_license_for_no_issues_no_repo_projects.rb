# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Set `project_settings.legacy_open_source_license_available` to false for public projects with no issues & no repo
    class DisableLegacyOpenSourceLicenseForNoIssuesNoRepoProjects < ::Gitlab::BackgroundMigration::BatchedMigrationJob
      PUBLIC = 20

      operation_name :disable_legacy_open_source_license_for_no_issues_no_repo_projects
      feature_category :database

      # Migration only version of `project_settings` table
      class ProjectSetting < ApplicationRecord
        self.table_name = 'project_settings'
      end

      def perform
        each_sub_batch(
          batching_scope: ->(relation) { relation.where(visibility_level: PUBLIC) }
        ) do |sub_batch|
          no_issues_no_repo_projects =
            sub_batch
              .joins('LEFT OUTER JOIN project_statistics ON project_statistics.project_id = projects.id')
              .joins('LEFT OUTER JOIN project_settings ON project_settings.project_id = projects.id')
              .joins('LEFT OUTER JOIN issues ON issues.project_id = projects.id')
              .where(
                'project_statistics.repository_size' => 0,
                'project_settings.legacy_open_source_license_available' => true)
              .group('projects.id')
              .having('COUNT(issues.id) = 0')

          ProjectSetting
            .where(project_id: no_issues_no_repo_projects)
            .update_all(legacy_open_source_license_available: false)
        end
      end
    end
  end
end
