# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowWorkItemsToIssues < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_work_items

  def up
    add_concurrent_foreign_key TABLE, :issues, column: :work_item_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :work_item_id
    end
  end
end
