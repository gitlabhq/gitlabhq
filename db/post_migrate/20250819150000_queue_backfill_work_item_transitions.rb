# frozen_string_literal: true

class QueueBackfillWorkItemTransitions < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillWorkItemTransitions"
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100
  MAX_BATCH_SIZE = 30_000
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :issues,
      :id,
      max_batch_size: MAX_BATCH_SIZE,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :issues, :id, [])
  end
end
