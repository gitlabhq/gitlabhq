# frozen_string_literal: true

class CreateAiUsageEventsDaily < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS ai_usage_events_daily
      (
          `namespace_path` String DEFAULT '0/',
          `date` Date32 DEFAULT toDate(now64()),
          `event` UInt16 DEFAULT 0,
          `user_id` UInt64 DEFAULT 0,
          `occurrences` UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, date, event, user_id)
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS ai_usage_events_daily
    SQL
  end
end
