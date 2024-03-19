# frozen_string_literal: true

class AddNodeIdForeignKeyToZoektTasks < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '16.10'

  def up
    add_concurrent_partitioned_foreign_key :zoekt_tasks, :zoekt_nodes, column: :zoekt_node_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_tasks, column: :zoekt_node_id
    end
  end
end
