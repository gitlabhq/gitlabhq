# frozen_string_literal: true

class QueueBackfillPlaceholderUsersDetailsFromSourceUsers < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillPlaceholderUsersDetailsFromSourceUsers"
  BATCH_SIZE = 1000
  SUB_BATCH_SIZE = 100
  DELAY_INTERVAL = 2.minutes

  def up
    queue_batched_background_migration(
      MIGRATION,
      :import_source_users,
      :id,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, :import_source_users, :id, [])
  end
end
