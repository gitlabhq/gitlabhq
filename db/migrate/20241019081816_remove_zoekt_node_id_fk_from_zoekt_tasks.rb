# frozen_string_literal: true

class RemoveZoektNodeIdFkFromZoektTasks < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers

  disable_ddl_transaction!
  milestone '17.6'

  CONSTRAINT_NAME = 'fk_rails_51af186590'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:zoekt_tasks, column: :zoekt_node_id, on_delete: :cascade, name: CONSTRAINT_NAME)
    end
  end

  def down
    add_concurrent_partitioned_foreign_key(:zoekt_tasks, :zoekt_nodes, column: :zoekt_node_id, on_delete: :cascade,
      name: CONSTRAINT_NAME)
  end
end
