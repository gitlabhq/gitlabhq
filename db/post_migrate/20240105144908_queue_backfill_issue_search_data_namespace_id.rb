# frozen_string_literal: true

class QueueBackfillIssueSearchDataNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  MIGRATION = "BackfillIssueSearchDataNamespaceId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 1_000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
