# frozen_string_literal: true

class FinalizeWorkspacesConfigVersion3Migration < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  MIGRATION = 'UpdateWorkspacesConfigVersion3'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: MIGRATION,
      table_name: :workspaces,
      column_name: :config_version,
      job_arguments: [],
      finalize: true
    )
  end

  def down
    # no-op
  end
end
