# frozen_string_literal: true

class AddWorkItemDecisionsWorkflowForeignKey < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :work_item_decisions, :duo_workflows_workflows,
      column: :workflow_id, on_delete: :nullify, reverse_lock_order: true
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :work_item_decisions, column: :workflow_id
    end
  end
end
