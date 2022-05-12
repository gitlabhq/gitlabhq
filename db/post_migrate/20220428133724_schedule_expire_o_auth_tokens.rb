# frozen_string_literal: true

class ScheduleExpireOAuthTokens < Gitlab::Database::Migration[2.0]
  MIGRATION = 'ExpireOAuthTokens'
  INTERVAL = 2.minutes.freeze

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      :oauth_access_tokens,
      :id,
      job_interval: INTERVAL
    )
  end

  def down
    Gitlab::Database::BackgroundMigration::BatchedMigration
      .for_configuration(MIGRATION, :oauth_access_tokens, :id, [])
      .delete_all
  end
end
