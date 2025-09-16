# frozen_string_literal: true

class FinalizeBackfillOperationsScopesProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOperationsScopesProjectId',
      table_name: :operations_scopes,
      column_name: :id,
      job_arguments: [:project_id, :operations_strategies, :project_id, :strategy_id],
      finalize: true
    )
  end

  def down; end
end
