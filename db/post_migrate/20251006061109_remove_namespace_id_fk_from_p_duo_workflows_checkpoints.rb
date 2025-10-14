# frozen_string_literal: true

class RemoveNamespaceIdFkFromPDuoWorkflowsCheckpoints < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  milestone '18.5'
  disable_ddl_transaction!
  FK_NAME = :fk_rails_0320b7accd

  def up
    remove_partitioned_foreign_key :p_duo_workflows_checkpoints, name: FK_NAME
  end

  def down
    add_concurrent_partitioned_foreign_key :p_duo_workflows_checkpoints, :namespaces, name: FK_NAME,
      column: :namespace_id, on_delete: :cascade, reverse_lock_order: true
  end
end
