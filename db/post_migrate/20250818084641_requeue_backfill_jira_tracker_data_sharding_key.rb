# frozen_string_literal: true

class RequeueBackfillJiraTrackerDataShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  MIGRATION = "BackfillJiraTrackerDataShardingKey"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  MAX_BATCH_SIZE = 10_000

  def up
    delete_batched_background_migration(MIGRATION, :jira_tracker_data, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :jira_tracker_data,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :jira_tracker_data, :id, [])
  end
end
