# frozen_string_literal: true

class BackfillAllProjectNamespaces < Gitlab::Database::Migration[1.0]
  MIGRATION = 'ProjectNamespaces::BackfillProjectNamespaces'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 5_000
  SUB_BATCH_SIZE = 10

  disable_ddl_transaction!

  def up
    queue_batched_background_migration(
      MIGRATION,
      :projects,
      :id,
      nil,
      'up',
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :projects, :id, [nil, 'up'])
  end
end
