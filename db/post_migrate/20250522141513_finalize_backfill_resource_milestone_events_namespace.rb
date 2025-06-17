# frozen_string_literal: true

class FinalizeBackfillResourceMilestoneEventsNamespace < Gitlab::Database::Migration[2.3]
  MIGRATION = "BackfillResourceMilestoneEventsNamespace"

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :resource_milestone_events,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
