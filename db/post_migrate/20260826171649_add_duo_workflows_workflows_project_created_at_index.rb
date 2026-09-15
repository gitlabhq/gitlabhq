# frozen_string_literal: true

class AddDuoWorkflowsWorkflowsProjectCreatedAtIndex < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  TABLE = :duo_workflows_workflows
  INDEX = 'index_duo_workflows_workflows_on_project_created_at'
  REDUNDANT_INDEX = 'index_duo_workflows_workflows_on_project_id'

  # The plain project_id index reads a project's whole history per probe; this composite avoids that.
  # The 2025 partial (project_id, environment, created_at) index is WorkflowsFinder's; untouched.
  # New composite still covers project_id alone, so fk_2f6398d8ee stays covered.
  def up
    add_concurrent_index TABLE, [:project_id, :created_at],
      order: { created_at: :DESC }, where: 'project_id IS NOT NULL', name: INDEX
    remove_concurrent_index_by_name TABLE, REDUNDANT_INDEX
  end

  def down
    add_concurrent_index TABLE, :project_id, name: REDUNDANT_INDEX
    remove_concurrent_index_by_name TABLE, INDEX
  end
end
