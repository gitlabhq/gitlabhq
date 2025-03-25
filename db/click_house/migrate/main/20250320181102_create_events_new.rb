# frozen_string_literal: true

class CreateEventsNew < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE events_new (
        id Int64 DEFAULT 0,
        path String DEFAULT '0/',
        author_id UInt64 DEFAULT 0,
        action UInt8 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        target_id UInt64 DEFAULT 0,
        created_at DateTime64(6, 'UTC') DEFAULT now(),
        updated_at DateTime64(6, 'UTC') DEFAULT now(),
        version DateTime64(6, 'UTC') DEFAULT NOW(),
        deleted Boolean DEFAULT false
      )
      ENGINE=ReplacingMergeTree(version, deleted)
      PRIMARY KEY id
      ORDER BY (id)
      PARTITION BY toYear(created_at)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS events_new
    SQL
  end
end
