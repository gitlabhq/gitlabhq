# frozen_string_literal: true

class QueueBackfillUsersColorModeId < Gitlab::Database::Migration[2.2]
  milestone '16.10'
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = "BackfillUsersColorModeId"
  DELAY_INTERVAL = 2.minutes
  TABLE_NAME = :users
  BATCH_COLUMN = :id
  BATCH_SIZE = 250
  SUB_BATCH_SIZE = 10
  MAX_BATCH_SIZE = 1000

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(MIGRATION, TABLE_NAME, BATCH_COLUMN, [])
  end
end
