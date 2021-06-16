# frozen_string_literal: true

class ScheduleCleanupOrphanedLfsObjectsProjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  MIGRATION = 'CleanupOrphanedLfsObjectsProjects'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000

  disable_ddl_transaction!

  class LfsObjectsProject < ActiveRecord::Base
    self.table_name = 'lfs_objects_projects'

    include ::EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(LfsObjectsProject, MIGRATION, DELAY_INTERVAL, batch_size: BATCH_SIZE)
  end

  def down
    # NOOP
  end
end
