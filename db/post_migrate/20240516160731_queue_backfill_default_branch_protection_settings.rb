# frozen_string_literal: true

class QueueBackfillDefaultBranchProtectionSettings < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  MIGRATION = "BackfillDefaultBranchProtectionSettings"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 25000
  SUB_BATCH_SIZE = 1000

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
