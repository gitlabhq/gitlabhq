# frozen_string_literal: true

class DropDuoWorkflowsCheckpointsNamespaceIdFk < Gitlab::Database::Migration[2.3]
  milestone '18.4'
  disable_ddl_transaction!

  FK_NAME = :fk_779e1a4594

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :duo_workflows_checkpoints, :namespaces, column: :namespace_id, name: FK_NAME,
        reverse_lock_order: true
    end
  end

  def down
    add_concurrent_foreign_key :duo_workflows_checkpoints, :namespaces,
      column: :namespace_id,
      name: FK_NAME,
      reverse_lock_order: true,
      on_delete: :cascade
  end
end
