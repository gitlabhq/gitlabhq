# frozen_string_literal: true

class CreateAiActiveContextCodeEnabledNamespaces < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers

  disable_ddl_transaction!
  milestone '18.2'

  TABLE_NAME = :p_ai_active_context_code_enabled_namespaces
  PARTITION_SIZE = 2_000_000

  def up
    with_lock_retries do
      create_table TABLE_NAME,
        options: 'PARTITION BY RANGE (namespace_id)',
        primary_key: [:id, :namespace_id], if_not_exists: true do |t|
        t.bigserial :id, null: false

        t.bigint :namespace_id, null: false,
          index: { name: 'idx_ai_active_context_code_enabled_namespaces_namespace_id' }
        t.bigint :connection_id, null: false

        t.jsonb :metadata, null: false, default: {}
        t.integer :state, limit: 2, null: false, default: 0
        t.timestamps_with_timezone null: false

        t.index [:connection_id, :namespace_id], unique: true,
          name: 'idx_unique_ai_code_repository_connection_namespace_id'
      end
    end

    create_partitions
  end

  def down
    drop_table TABLE_NAME
  end

  private

  def create_partitions
    min_id = Namespace.connection
      .select_value("select min_value from pg_sequences where sequencename = 'namespaces_id_seq'") || 1

    max_id = Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas.with_suppressed do
      Gitlab::Database::QueryAnalyzers::GitlabSchemasValidateConnection.with_suppressed do
        define_batchable_model('namespaces', connection: connection).maximum(:id) || min_id
      end
    end

    create_int_range_partitions(TABLE_NAME, PARTITION_SIZE, min_id, max_id)
  end
end
