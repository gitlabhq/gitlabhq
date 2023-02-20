# frozen_string_literal: true

class ScheduleVulnerabilitiesFeedbackMigration4 < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition'
  TABLE_NAME = :vulnerability_feedback
  BATCH_COLUMN = :id
  JOB_INTERVAL = 2.minutes
  BATCH_SIZE = 250
  SUB_BATCH_SIZE = 5

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # Delete the previous jobs
    delete_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      []
    )

    # Reschedule the migration
    queue_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      job_interval: JOB_INTERVAL,
      batch_size: BATCH_SIZE,
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
