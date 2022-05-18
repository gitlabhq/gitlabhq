# frozen_string_literal: true

class RescheduleExpireOAuthTokens < Gitlab::Database::Migration[2.0]
  MIGRATION = 'ExpireOAuthTokens'
  INTERVAL = 2.minutes.freeze

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # remove the original migration from db/post_migrate/20220428133724_schedule_expire_o_auth_tokens.rb
    delete_batched_background_migration(MIGRATION, :oauth_access_tokens, :id, [])

    # reschedule
    queue_batched_background_migration(
      MIGRATION,
      :oauth_access_tokens,
      :id,
      job_interval: INTERVAL
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :oauth_access_tokens, :id, [])
  end
end
