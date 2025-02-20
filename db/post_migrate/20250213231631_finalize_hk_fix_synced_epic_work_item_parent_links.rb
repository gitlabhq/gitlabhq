# frozen_string_literal: true

class FinalizeHkFixSyncedEpicWorkItemParentLinks < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'FixSyncedEpicWorkItemParentLinks',
      table_name: :epics,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
