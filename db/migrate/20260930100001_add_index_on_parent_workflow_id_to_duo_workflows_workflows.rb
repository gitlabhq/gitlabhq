# frozen_string_literal: true

class AddIndexOnParentWorkflowIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_duo_workflows_workflows_on_parent_workflow_id'

  def up
    add_concurrent_index :duo_workflows_workflows, :parent_workflow_id,
      where: 'parent_workflow_id IS NOT NULL',
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :duo_workflows_workflows, INDEX_NAME
  end
end
