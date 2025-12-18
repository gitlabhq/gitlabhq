# frozen_string_literal: true

class CreateSiphonKnowledgeGraphEnabledNamespaces < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_knowledge_graph_enabled_namespaces
      (
        id Int64,
        root_namespace_id Int64,
        created_at DateTime64(6, 'UTC'),
        updated_at DateTime64(6, 'UTC'),
        _siphon_replicated_at DateTime64(6, 'UTC') DEFAULT now(),
        _siphon_deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(_siphon_replicated_at, _siphon_deleted)
      PRIMARY KEY (root_namespace_id, id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_knowledge_graph_enabled_namespaces
    SQL
  end
end
