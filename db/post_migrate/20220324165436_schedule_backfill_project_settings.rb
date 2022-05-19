# frozen_string_literal: true

class ScheduleBackfillProjectSettings < Gitlab::Database::Migration[1.0]
  MIGRATION = 'BackfillProjectSettings'
  INTERVAL = 2.minutes
  BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 200

  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      job_interval: INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [])
  end
end
