# frozen_string_literal: true

class FinalizeBackfillEpicDatesToWorkItemDatesSources < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillEpicDatesToWorkItemDatesSources',
      table_name: 'epics',
      column_name: 'id',
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
