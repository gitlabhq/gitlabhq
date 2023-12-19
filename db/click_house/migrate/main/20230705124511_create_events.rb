# frozen_string_literal: true

class CreateEvents < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS events
      (
        id UInt64 DEFAULT 0,
        path String DEFAULT '0/', -- the event_namespace_paths MV depends on this format
        author_id UInt64 DEFAULT 0,
        target_id UInt64 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        action UInt8 DEFAULT 0,
        deleted UInt8 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        updated_at DateTime64(6, 'UTC') DEFAULT now()
      )
      ENGINE = ReplacingMergeTree(updated_at, deleted)
      PRIMARY KEY (id)
      ORDER BY (id)
      PARTITION BY toYear(created_at)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE events
    SQL
  end
end
