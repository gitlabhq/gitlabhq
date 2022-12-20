# frozen_string_literal: true

class ScheduleVulnerabilitiesFeedbackMigration < Gitlab::Database::Migration[2.0]
  MIGRATION = 'MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition'
  TABLE_NAME = :vulnerability_feedback
  BATCH_COLUMN = :id
  DELAY_INTERVAL = 5.minutes
  BATCH_SIZE = 250
  MAX_BATCH_SIZE = 250
  SUB_BATCH_SIZE = 50

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      job_interval: DELAY_INTERVAL,
      batch_size: BATCH_SIZE,
      max_batch_size: MAX_BATCH_SIZE,
      sub_batch_size: SUB_BATCH_SIZE
    )
  end

  def down
    delete_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      []
    )
  end
end
