# frozen_string_literal: true

class QueueBackfillUserPreferencesWithDefaults < Gitlab::Database::Migration[2.1]
  MIGRATION = "BackfillUserPreferencesWithDefaults"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 3_000
  SUB_BATCH_SIZE = 200
  MAX_BATCH_SIZE = 10_000

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :user_preferences,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :user_preferences, :id, [])
  end
end
