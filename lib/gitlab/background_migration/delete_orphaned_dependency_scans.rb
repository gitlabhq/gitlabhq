# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class DeleteOrphanedDependencyScans < BatchedMigrationJob
      operation_name :delete_orphaned_dependency_scans
      feature_category :software_composition_analysis

      # Only delete scans that have been in created state for more than 7 days
      STALE_THRESHOLD = 7.days
      DEPENDENCY_SCANNING = 2
      CREATED = 0

      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where(scan_type: DEPENDENCY_SCANNING, status: CREATED)
            .where(created_at: ...STALE_THRESHOLD.ago)
            .delete_all
        end
      end
    end
  end
end
