# frozen_string_literal: true

class ReplaceZoektIndicesIndexOnNodeId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.11'

  NEW_INDEX_NAME = 'index_zoekt_indices_on_zoekt_node_id_and_id'
  OLD_INDEX_NAME = 'index_zoekt_indices_on_zoekt_node_id'

  def up
    add_concurrent_index :zoekt_indices, %i[zoekt_node_id id], name: NEW_INDEX_NAME, unique: true
    remove_concurrent_index_by_name :zoekt_indices, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :zoekt_indices, :zoekt_node_id, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :zoekt_indices, NEW_INDEX_NAME
  end
end
