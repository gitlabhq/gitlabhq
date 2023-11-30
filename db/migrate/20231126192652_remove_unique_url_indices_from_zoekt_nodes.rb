# frozen_string_literal: true

class RemoveUniqueUrlIndicesFromZoektNodes < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  INDEX_NAME_INDEX_URL = 'index_zoekt_nodes_on_index_base_url'
  INDEX_NAME_SEARCH_URL = 'index_zoekt_nodes_on_search_base_url'

  def up
    remove_concurrent_index :zoekt_nodes, :index_base_url, name: INDEX_NAME_INDEX_URL
    remove_concurrent_index :zoekt_nodes, :search_base_url, name: INDEX_NAME_SEARCH_URL
  end

  def down
    add_concurrent_index :zoekt_nodes, :index_base_url, unique: true, name: INDEX_NAME_INDEX_URL
    add_concurrent_index :zoekt_nodes, :search_base_url, unique: true, name: INDEX_NAME_SEARCH_URL
  end
end
