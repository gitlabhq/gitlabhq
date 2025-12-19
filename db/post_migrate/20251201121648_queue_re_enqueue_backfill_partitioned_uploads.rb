# frozen_string_literal: true

class QueueReEnqueueBackfillPartitionedUploads < Gitlab::Database::Migration[2.3]
  milestone '18.8'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = "BackfillPartitionedUploads"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 7000
  SUB_BATCH_SIZE = 300

  def up
    delete_batched_background_migration(MIGRATION, :uploads, :id, [])

    queue_batched_background_migration(
      MIGRATION,
      :uploads,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :uploads, :id, [])
  end
end
