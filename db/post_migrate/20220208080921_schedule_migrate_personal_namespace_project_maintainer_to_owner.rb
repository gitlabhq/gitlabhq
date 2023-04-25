# frozen_string_literal: true

class ScheduleMigratePersonalNamespaceProjectMaintainerToOwner < Gitlab::Database::Migration[1.0]
  MIGRATION = 'MigratePersonalNamespaceProjectMaintainerToOwner'
  INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  SUB_BATCH_SIZE = 200

  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      MIGRATION,
      :members,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    # no-op
  end
end
