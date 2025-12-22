# frozen_string_literal: true

class DropTablePKnowledgeGraphEnabledNamespaces < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  disable_ddl_transaction!
  milestone '18.8'

  def up
    with_lock_retries do
      drop_table :p_knowledge_graph_enabled_namespaces, if_exists: true
    end
  end

  def down
    with_lock_retries do
      create_table :p_knowledge_graph_enabled_namespaces,
        options: 'PARTITION BY RANGE (namespace_id)',
        primary_key: [:id, :namespace_id], if_not_exists: true do |t|
        t.bigserial :id, null: false
        t.bigint :namespace_id, null: false
        t.timestamps_with_timezone null: false
        t.integer :state, null: false, default: 0, limit: 2, index: true
        t.index :namespace_id, unique: true
      end
    end

    unless has_loose_foreign_key?(:p_knowledge_graph_enabled_namespaces)
      track_record_deletions_override_table_name(:p_knowledge_graph_enabled_namespaces)
    end

    add_concurrent_partitioned_foreign_key :p_knowledge_graph_enabled_namespaces, :namespaces,
      column: :namespace_id, on_delete: :cascade
  end
end
