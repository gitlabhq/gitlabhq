# frozen_string_literal: true

class ScheduleResetDuplicateCiRunnersTokenEncryptedValues < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  MIGRATION = 'ResetDuplicateCiRunnersTokenEncryptedValues'
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 2_000
  MAX_BATCH_SIZE = 100_000
  SUB_BATCH_SIZE = 500

  def up
    queue_batched_background_migration(
      MIGRATION,
      :ci_runners,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :ci_runners, :id, [])
  end
end
