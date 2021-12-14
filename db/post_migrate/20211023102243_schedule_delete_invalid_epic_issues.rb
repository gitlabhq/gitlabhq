# frozen_string_literal: true

class ScheduleDeleteInvalidEpicIssues < Gitlab::Database::Migration[1.0]
  MIGRATION = 'DeleteInvalidEpicIssues'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('epics'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
  end
end
