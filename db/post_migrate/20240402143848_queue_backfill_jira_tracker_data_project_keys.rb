# frozen_string_literal: true

class QueueBackfillJiraTrackerDataProjectKeys < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillJiraTrackerDataProjectKeys"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
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
    delete_batched_background_migration(MIGRATION, :jira_tracker_data, :id, [])
  end
end
