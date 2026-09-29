# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowWorkflowsToLinkedWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.5'

  TABLE = :duo_workflows_workflow_workflows

  def up
    add_concurrent_foreign_key TABLE, :duo_workflows_workflows, column: :linked_workflow_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :linked_workflow_id
    end
  end
end
