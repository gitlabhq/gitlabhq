# frozen_string_literal: true

class FinalizeRequeueBackfillWorkItemHierarchyForEpics < Gitlab::Database::Migration[2.2]
  MIGRATION = 'RequeueBackfillWorkItemHierarchyForEpics'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.9'

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :epics,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
