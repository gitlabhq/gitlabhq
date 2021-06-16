# frozen_string_literal: true

class ScheduleUpdateJiraTrackerDataDeploymentTypeBasedOnUrl < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'UpdateJiraTrackerDataDeploymentTypeBasedOnUrl'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 2_500

  disable_ddl_transaction!

  def up
    say "Scheduling #{MIGRATION} jobs"
    queue_background_migration_jobs_by_range_at_intervals(
      define_batchable_model('jira_tracker_data'),
      MIGRATION,
      DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
