# frozen_string_literal: true

class QueueTrimLastUsedIpsToLimit < Gitlab::Database::Migration[2.3]
  milestone '19.4'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  MIGRATION = 'TrimLastUsedIpsToLimit'
  BATCH_SIZE = 10_000
  SUB_BATCH_SIZE = 100
  PAUSE_MS = 100
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :personal_access_token_last_used_ips,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      pause_ms: PAUSE_MS
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :personal_access_token_last_used_ips, :id, [])
  end
end
