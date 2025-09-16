# frozen_string_literal: true

class FinalizeBackfillWorkspaceVariablesProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillWorkspaceVariablesProjectId',
      table_name: :workspace_variables,
      column_name: :id,
      job_arguments: [:project_id, :workspaces, :project_id, :workspace_id],
      finalize: true
    )
  end

  def down; end
end
