# frozen_string_literal: true

class AddZoektNodeForeignKeyToIndexedNamespaces < Gitlab::Database::Migration[2.2]
  milestone '16.6'
  disable_ddl_transaction!

  INDEX_NAME = 'index_zoekt_node_and_namespace'

  def up
    add_concurrent_foreign_key :zoekt_indexed_namespaces, :zoekt_nodes, column: :zoekt_node_id, on_delete: :cascade
    add_concurrent_index :zoekt_indexed_namespaces, [:zoekt_node_id, :namespace_id], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :zoekt_indexed_namespaces, [:zoekt_node_id, :namespace_id], name: INDEX_NAME
  end
end
