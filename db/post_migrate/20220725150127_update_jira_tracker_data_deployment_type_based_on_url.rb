# frozen_string_literal: true

class UpdateJiraTrackerDataDeploymentTypeBasedOnUrl < Gitlab::Database::Migration[2.0]
  MIGRATION = 'UpdateJiraTrackerDataDeploymentTypeBasedOnUrl'
  DELAY_INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 2_500
  SUB_BATCH_SIZE = 2_500

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    say "Scheduling #{MIGRATION} jobs"
    delete_queued_jobs(MIGRATION)
    queue_batched_background_migration(
      MIGRATION,
      :jira_tracker_data,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
