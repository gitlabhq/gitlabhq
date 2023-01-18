# frozen_string_literal: true

class CleanupOAuthAccessTokensWithNullExpiresIn < Gitlab::Database::Migration[2.1]
  MIGRATION = 'ReExpireOAuthTokens'
  INTERVAL = 2.minutes
  MAX_BATCH_SIZE = 50_000

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :oauth_access_tokens,
      :id,
      job_interval: INTERVAL,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :oauth_access_tokens, :id, [])
  end
end
