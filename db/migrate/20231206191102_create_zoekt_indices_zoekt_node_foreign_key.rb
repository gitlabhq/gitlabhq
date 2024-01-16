# frozen_string_literal: true

class CreateZoektIndicesZoektNodeForeignKey < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  def up
    add_concurrent_foreign_key :zoekt_indices, :zoekt_nodes, column: :zoekt_node_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :zoekt_indices, column: :zoekt_node_id
    end
  end
end
