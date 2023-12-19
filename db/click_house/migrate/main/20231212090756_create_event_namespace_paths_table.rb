# frozen_string_literal: true

class CreateEventNamespacePathsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS event_namespace_paths
      (
        namespace_id UInt64 DEFAULT 0,
        path String DEFAULT '',
        deleted UInt8 DEFAULT 0,
        last_event_at DateTime64(6, 'UTC') DEFAULT now64()
      )
      ENGINE = ReplacingMergeTree(last_event_at, deleted)
      PRIMARY KEY (namespace_id)
      ORDER BY (namespace_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS event_namespace_paths
    SQL
  end
end
