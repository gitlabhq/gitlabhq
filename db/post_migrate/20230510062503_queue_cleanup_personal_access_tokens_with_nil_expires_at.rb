# frozen_string_literal: true

class QueueCleanupPersonalAccessTokensWithNilExpiresAt < Gitlab::Database::Migration[2.1]
  MIGRATION = "CleanupPersonalAccessTokensWithNilExpiresAt"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 50_000

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :personal_access_tokens,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :personal_access_tokens, :id, [])
  end
end
