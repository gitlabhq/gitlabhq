# frozen_string_literal: true

class RemoveZoektIndexedNamespacesForeignKeys < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'

  NAMESPACES_FK_NAME = 'fk_3bebdb4efc'
  ZOEKT_NODES_FK_NAME = 'fk_9267f4de0c'
  ZOEKT_SHARDS_FK_NAME = 'fk_rails_4f6006e94c'

  def up
    with_lock_retries do
      remove_foreign_key_if_exists :zoekt_indexed_namespaces, column: :namespace_id
      remove_foreign_key_if_exists :zoekt_indexed_namespaces, column: :zoekt_node_id
      remove_foreign_key_if_exists :zoekt_indexed_namespaces, column: :zoekt_shard_id
    end
  end

  def down
    add_concurrent_foreign_key :zoekt_indexed_namespaces, :namespaces, column: :namespace_id,
      on_delete: :cascade, name: NAMESPACES_FK_NAME
    add_concurrent_foreign_key :zoekt_indexed_namespaces, :zoekt_nodes, column: :zoekt_node_id,
      on_delete: :cascade, name: ZOEKT_NODES_FK_NAME
    add_concurrent_foreign_key :zoekt_indexed_namespaces, :zoekt_shards, column: :zoekt_shard_id,
      on_delete: :cascade, name: ZOEKT_SHARDS_FK_NAME
  end
end
