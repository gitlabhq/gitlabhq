# frozen_string_literal: true

class SchedulePopulateTestReportsIssueId < Gitlab::Database::Migration[1.0]
  MIGRATION = 'PopulateTestReportsIssueId'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 30

  disable_ddl_transaction!

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('requirements_management_test_reports').where(issue_id: nil),
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
