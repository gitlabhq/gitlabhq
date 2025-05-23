# frozen_string_literal: true

class AddKnowledgeGraphReplicas < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :p_knowledge_graph_replicas
  PARTITION_SIZE = 2_000_000
  MIN_ID = Namespace.connection
    .select_value("select min_value from pg_sequences where sequencename = 'namespaces_id_seq'") || 1

  def up
    with_lock_retries do
      create_table TABLE_NAME,
        options: 'PARTITION BY RANGE (namespace_id)',
        primary_key: [:id, :namespace_id], if_not_exists: true do |t|
        t.bigserial :id, null: false
        t.bigint :namespace_id, null: false
        t.bigint :knowledge_graph_enabled_namespace_id, null: true
        t.bigint :zoekt_node_id, null: false, index: true
        t.timestamps_with_timezone null: false
        t.integer :state, null: false, index: true, default: 0, limit: 2
        t.integer :retries_left, limit: 2, null: false
        t.index :namespace_id, unique: true,
          name: 'index_p_knowledge_graph_replicas_on_namespace_id', using: :btree
        t.check_constraint 'retries_left > 0 OR retries_left = 0 AND state >= 200',
          name: 'c_p_knowledge_graph_replicas_retries_status'
      end
    end

    create_partitions
  end

  def down
    drop_table TABLE_NAME
  end

  private

  def create_partitions
    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('namespaces', connection: connection).maximum(:id) || MIN_ID
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, MIN_ID, max_id)
  end
end
