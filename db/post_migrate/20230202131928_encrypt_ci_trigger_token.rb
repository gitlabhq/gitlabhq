# frozen_string_literal: true

class EncryptCiTriggerToken < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_ci

  MIGRATION = 'EncryptCiTriggerToken'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 1_000
  MAX_BATCH_SIZE = 2_000
  SUB_BATCH_SIZE = 100

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_triggers,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_triggers, :id, [])
  end
end
