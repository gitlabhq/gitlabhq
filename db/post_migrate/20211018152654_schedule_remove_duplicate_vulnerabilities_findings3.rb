# frozen_string_literal: true

class ScheduleRemoveDuplicateVulnerabilitiesFindings3 < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  MIGRATION = 'RemoveDuplicateVulnerabilitiesFindings'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 5_000

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('vulnerability_occurrences'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
