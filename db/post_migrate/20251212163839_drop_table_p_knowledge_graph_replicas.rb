# frozen_string_literal: true

class DropTablePKnowledgeGraphReplicas < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.8'

  def up
    with_lock_retries do
      drop_table :p_knowledge_graph_replicas, if_exists: true
    end
  end

  def down
    with_lock_retries do
      create_table :p_knowledge_graph_replicas,
        options: 'PARTITION BY RANGE (namespace_id)',
        primary_key: [:id, :namespace_id], if_not_exists: true do |t|
        t.bigserial :id, null: false
        t.bigint :namespace_id, null: false
        t.bigint :knowledge_graph_enabled_namespace_id, null: true
        t.bigint :zoekt_node_id, null: false, index: true
        t.timestamps_with_timezone null: false
        t.integer :state, null: false, index: true, default: 0, limit: 2
        t.integer :retries_left, limit: 2, null: false
        t.bigint :reserved_storage_bytes, default: 10 * 1024 * 1024, null: false
        t.datetime_with_timezone :indexed_at
        t.column :schema_version, :smallint, default: 0, null: false
        t.index :namespace_id,
          name: 'index_p_knowledge_graph_replicas_on_namespace_id', using: :btree
        t.index :schema_version,
          name: 'index_p_knowledge_graph_replicas_on_schema_version', using: :btree
        t.check_constraint 'retries_left > 0 OR retries_left = 0 AND state >= 200',
          name: 'c_p_knowledge_graph_replicas_retries_status'
      end
    end

    add_concurrent_partitioned_foreign_key :p_knowledge_graph_replicas, :zoekt_nodes,
      column: :zoekt_node_id, on_delete: :cascade

    add_concurrent_partitioned_index :p_knowledge_graph_replicas,
      [:knowledge_graph_enabled_namespace_id, :zoekt_node_id, :namespace_id], unique: true,
      name: 'p_knowledge_graph_replicas_namespace_id_and_zoekt_node_id'
  end
end
