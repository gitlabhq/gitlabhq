# frozen_string_literal: true

class ScheduleBackfillTopicsTitle < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillTopicsTitle'
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('topics'),
      MIGRATION,
      DELAY_INTERVAL,
      track_jobs: true
    )
  end

  def down
    # no-op
  end
end
