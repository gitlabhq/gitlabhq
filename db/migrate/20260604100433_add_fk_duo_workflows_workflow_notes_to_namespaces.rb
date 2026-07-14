# frozen_string_literal: true

class AddFkDuoWorkflowsWorkflowNotesToNamespaces < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  TABLE = :duo_workflows_workflow_notes

  def up
    add_concurrent_foreign_key TABLE, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE, column: :namespace_id
    end
  end
end
