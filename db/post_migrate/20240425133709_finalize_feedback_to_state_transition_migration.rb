# frozen_string_literal: true

class FinalizeFeedbackToStateTransitionMigration < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.0'

  MIGRATION_NAME = "MigrateVulnerabilitiesFeedbackToVulnerabilitiesStateTransition"

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION_NAME,
      table_name: :vulnerability_feedback,
      column_name: :id,
      job_arguments: []
    )
  end

  def down
    # no-op
  end
end
