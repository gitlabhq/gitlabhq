# frozen_string_literal: true

class DropAuditEvents < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP TABLE IF EXISTS audit_events;
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS audit_events
      (
          id UInt64 DEFAULT 0,
          author_id UInt64 DEFAULT 0,
          author_name String DEFAULT '',
          created_at DateTime64(6, 'UTC') DEFAULT now(),
          details String DEFAULT '',
          entity_id UInt64 DEFAULT 0,
          entity_path String DEFAULT '',
          entity_type LowCardinality(String) DEFAULT '',
          ip_address String DEFAULT '',
          target_details String DEFAULT '',
          target_id UInt64 DEFAULT 0,
          target_type LowCardinality(String) DEFAULT '',
          is_deleted UInt8 DEFAULT 0,
      ) ENGINE = ReplacingMergeTree(created_at, is_deleted)
      PARTITION BY toYear(created_at)
      ORDER BY (entity_type, entity_id, author_id, created_at, id);
    SQL

    execute <<~SQL
      ALTER TABLE audit_events
      ADD PROJECTION IF NOT EXISTS by_id (SELECT * ORDER BY id);
    SQL
  end
end
