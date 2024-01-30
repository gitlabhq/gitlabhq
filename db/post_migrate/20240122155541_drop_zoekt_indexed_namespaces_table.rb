# frozen_string_literal: true

class DropZoektIndexedNamespacesTable < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.9'

  ZOEKT_NODE_ID_IDX_NAME = 'index_zoekt_indices_on_zoekt_node_id'
  ZOEKT_NODE_AND_NAMESPACE_IDX_NAME = 'index_zoekt_node_and_namespace'
  ZOEKT_SHARD_AND_NAMESPACE_IDX_NAME = 'index_zoekt_shard_and_namespace'

  def up
    drop_table :zoekt_indexed_namespaces
  end

  def down
    create_table :zoekt_indexed_namespaces do |t|
      t.bigint :zoekt_node_id
      t.bigint :zoekt_shard_id
      t.bigint :namespace_id, null: false, index: true
      t.timestamps_with_timezone
      t.boolean :search, default: true, null: false
    end

    add_concurrent_index :zoekt_indexed_namespaces, [:zoekt_shard_id, :namespace_id],
      unique: true, name: ZOEKT_SHARD_AND_NAMESPACE_IDX_NAME
    add_concurrent_index :zoekt_indexed_namespaces, [:zoekt_node_id, :namespace_id],
      unique: true, name: ZOEKT_NODE_AND_NAMESPACE_IDX_NAME
  end
end
