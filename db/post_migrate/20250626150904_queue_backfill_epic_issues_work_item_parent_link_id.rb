# frozen_string_literal: true

class QueueBackfillEpicIssuesWorkItemParentLinkId < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillEpicIssuesWorkItemParentLinkId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :epic_issues,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :epic_issues, :id, [])
  end
end
