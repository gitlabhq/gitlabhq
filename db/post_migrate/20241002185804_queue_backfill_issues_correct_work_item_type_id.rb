# frozen_string_literal: true

class QueueBackfillIssuesCorrectWorkItemTypeId < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  # Select the applicable gitlab schema for your batched background migration
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillIssuesCorrectWorkItemTypeId"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  MAX_BATCH_SIZE = 30_000
  SUB_BATCH_SIZE = 50

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
