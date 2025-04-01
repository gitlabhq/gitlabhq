# frozen_string_literal: true

class AddStateZoektNodeIdIndexToZoektIndices < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.11'

  INDEX_NAME = 'index_zoekt_indices_on_state_and_zoekt_node_id'

  def up
    add_concurrent_index :zoekt_indices, [:state, :zoekt_node_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :zoekt_indices, INDEX_NAME
  end
end
