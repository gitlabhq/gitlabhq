# frozen_string_literal: true

class BackfillUserNamespace < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillUserNamespace'
  INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 200
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      MIGRATION,
      :namespaces,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :namespaces, :id, [])
  end
end
