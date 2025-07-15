# frozen_string_literal: true

class CreateAiUsageEventsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS ai_usage_events
        (
          user_id UInt64,
          event UInt16,
          timestamp DateTime64(6, 'UTC'),
          namespace_path String DEFAULT '0/',
          extras String DEFAULT '{}'
        ) ENGINE = ReplacingMergeTree
        PARTITION BY toYYYYMM(timestamp)
        ORDER BY (namespace_path, event, timestamp, user_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS ai_usage_events
    SQL
  end
end
