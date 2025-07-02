# frozen_string_literal: true

class AddNamespaceIdFkToDuoWorkflowsCheckpointWrites < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :duo_workflows_checkpoint_writes, :namespaces, column: :namespace_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_checkpoint_writes, column: :namespace_id
    end
  end
end
