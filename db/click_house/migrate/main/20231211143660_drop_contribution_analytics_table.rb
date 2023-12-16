# frozen_string_literal: true

class DropContributionAnalyticsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP TABLE IF EXISTS contribution_analytics_events
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS contribution_analytics_events
      (
        id UInt64 DEFAULT 0,
        path String DEFAULT '',
        author_id UInt64 DEFAULT 0,
        target_type LowCardinality(String) DEFAULT '',
        action UInt8 DEFAULT 0,
        created_at Date DEFAULT toDate(now()),
        updated_at DateTime64(6, 'UTC') DEFAULT now()
      )
      ENGINE = ReplacingMergeTree
      ORDER BY (path, created_at, author_id, id)
      PARTITION BY toYear(created_at);
    SQL
  end
end
