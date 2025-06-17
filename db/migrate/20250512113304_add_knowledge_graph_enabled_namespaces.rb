# frozen_string_literal: true

class AddKnowledgeGraphEnabledNamespaces < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.1'

  TABLE_NAME = :p_knowledge_graph_enabled_namespaces
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
        t.timestamps_with_timezone null: false
        t.integer :state, null: false, default: 0, limit: 2, index: true
        t.index :namespace_id, unique: true
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
