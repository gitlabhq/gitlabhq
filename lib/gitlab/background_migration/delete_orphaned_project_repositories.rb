# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Deletes project_repositories rows whose project_id has no matching projects row.
    # The ON DELETE CASCADE on fk_57201a9be7 removes any dependent project_repository_states.
    class DeleteOrphanedProjectRepositories < BatchedMigrationJob
      operation_name :delete_orphaned_project_repositories
      feature_category :geo_replication

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .joins('LEFT OUTER JOIN projects ON project_repositories.project_id = projects.id')
            .where(projects: { id: nil })
            .delete_all
        end
      end
    end
  end
end
