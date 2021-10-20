# frozen_string_literal: true

class ReschedulePendingJobsForRecalculateVulnerabilitiesOccurrencesUuid < Gitlab::Database::Migration[1.0]
  MIGRATION = "RecalculateVulnerabilitiesOccurrencesUuid"
  DELAY_INTERVAL = 2.minutes

  disable_ddl_transaction!

  def up
    delete_queued_jobs(MIGRATION)

    requeue_background_migration_jobs_by_range_at_intervals(MIGRATION, DELAY_INTERVAL)
  end

  def down
    # no-op
  end
end
