# frozen_string_literal: true

class QueueBackfillRootStorageStatisticsForkStorageSizes < Gitlab::Database::Migration[2.1]
  MIGRATION = "BackfillRootStorageStatisticsForkStorageSizes"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespace_root_storage_statistics,
      :namespace_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespace_root_storage_statistics, :namespace_id, [])
  end
end
