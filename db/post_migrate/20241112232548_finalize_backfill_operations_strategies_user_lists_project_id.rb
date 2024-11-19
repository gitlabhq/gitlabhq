# frozen_string_literal: true

class FinalizeBackfillOperationsStrategiesUserListsProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillOperationsStrategiesUserListsProjectId',
      table_name: :operations_strategies_user_lists,
      column_name: :id,
      job_arguments: [:project_id, :operations_user_lists, :project_id, :user_list_id],
      finalize: true
    )
  end

  def down; end
end
