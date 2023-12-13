# frozen_string_literal: true

class CreateContributionsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS contributions
      (
        id UInt64 DEFAULT 0,
        path String DEFAULT '',
        author_id UInt64 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        action UInt8 DEFAULT 0,
        created_at Date DEFAULT toDate(now64()),
        updated_at DateTime64(6, 'UTC') DEFAULT now64()
      )
      ENGINE = ReplacingMergeTree
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYear(created_at);
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS contributions
    SQL
  end
end
