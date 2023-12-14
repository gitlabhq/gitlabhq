# frozen_string_literal: true

class QueueBackfillBranchProtectionNamespaceSetting < Gitlab::Database::Migration[2.2]
  milestone "16.7"
  MIGRATION = "BackfillBranchProtectionNamespaceSetting"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespace_settings,
      :namespace_id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespace_settings, :namespace_id, [])
  end
end
