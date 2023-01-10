# frozen_string_literal: true

class QueueBackfillAdminModeScopeForPersonalAccessTokens < Gitlab::Database::Migration[2.1]
  MIGRATION = 'BackfillAdminModeScopeForPersonalAccessTokens'
  DELAY_INTERVAL = 2.minutes

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :personal_access_tokens,
      :id,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :personal_access_tokens, :id, [])
  end
end
