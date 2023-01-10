# frozen_string_literal: true

class DeleteQueuedJobsForVulnerabilitiesFeedbackMigration < Gitlab::Database::Migration[2.1]
  MIGRATION = 'MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition'
  TABLE_NAME = :vulnerability_feedback
  BATCH_COLUMN = :id

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    delete_batched_background_migration(
      MIGRATION,
      TABLE_NAME,
      BATCH_COLUMN,
      []
    )
  end

  def down
    # no-op
  end
end
