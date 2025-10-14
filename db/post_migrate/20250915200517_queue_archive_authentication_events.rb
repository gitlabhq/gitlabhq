# frozen_string_literal: true

class QueueArchiveAuthenticationEvents < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "ArchiveAuthenticationEvents"
  DELAY_INTERVAL = 2.minutes
  BATCH_SIZE = 10000
  SUB_BATCH_SIZE = 1000

  def up
    return unless Gitlab.com_except_jh?

    queue_batched_background_migration(
      MIGRATION,
      :authentication_events,
      :id,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      job_interval: DELAY_INTERVAL
    )
  end

  def down
    return unless Gitlab.com_except_jh?

    delete_batched_background_migration(MIGRATION, :authentication_events, :id, [])
  end
end
