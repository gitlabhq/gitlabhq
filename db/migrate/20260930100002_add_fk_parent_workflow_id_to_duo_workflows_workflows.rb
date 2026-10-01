# frozen_string_literal: true

class AddFkParentWorkflowIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  FK_NAME = 'fk_duo_workflows_workflows_parent_workflow_id'

  def up
    add_concurrent_foreign_key :duo_workflows_workflows, :duo_workflows_workflows,
      column: :parent_workflow_id,
      on_delete: :nullify,
      name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_workflows, column: :parent_workflow_id, name: FK_NAME
    end
  end
end
