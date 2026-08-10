# frozen_string_literal: true

class QueueCleanupDualShardingKeysInNotes < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "CleanupDualShardingKeysInNotes"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25_000
  SUB_BATCH_SIZE = 250

  def up
    queue_batched_background_migration(
      MIGRATION,
      :notes,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :notes, :id, [])
  end
end
