# frozen_string_literal: true

class ScheduleDeleteOrphanedDeployments < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'DeleteOrphanedDeployments'
  BATCH_SIZE = 100_000
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('deployments'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
