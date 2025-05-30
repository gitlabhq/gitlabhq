# frozen_string_literal: true

class RemoveOldCodeSuggestionsTables < ClickHouse::Migration
  def up
    execute "DROP TABLE IF EXISTS code_suggestion_usages" # new table code_suggestion_events
    execute "DROP TABLE IF EXISTS code_suggestion_daily_events" # new table code_suggestion_events_daily
    execute "DROP TABLE IF EXISTS code_suggestion_daily_events_new"
    execute "DROP VIEW IF EXISTS code_suggestion_daily_events_mv" # new view code_suggestion_events_daily_mv
    execute "DROP VIEW IF EXISTS code_suggestion_daily_events_mv_new"
  end

  def down
    execute <<~SQL
      CREATE TABLE code_suggestion_usages
      (
          `user_id` UInt64 DEFAULT 0,
          `event` UInt8 DEFAULT 0,
          `namespace_path` String DEFAULT '0/',
          `timestamp` DateTime64(6, 'UTC') DEFAULT now64(),
          `unique_tracking_id` String DEFAULT '',
          `language` LowCardinality(String) DEFAULT '',
          `suggestion_size` UInt64 DEFAULT 0,
          `branch_name` String DEFAULT ''
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, event, timestamp)
      SETTINGS index_granularity = 8192
    SQL

    execute <<~SQL
      CREATE TABLE code_suggestion_daily_events
      (
          `user_id` UInt64 DEFAULT 0,
          `date` Date32 DEFAULT toDate(now64()),
          `event` UInt8 DEFAULT 0,
          `occurrences` UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (user_id, date, event)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE TABLE code_suggestion_daily_events_new
      (
          `namespace_path` String DEFAULT '0/',
          `user_id` UInt64 DEFAULT 0,
          `date` Date32 DEFAULT toDate(now64()),
          `event` UInt8 DEFAULT 0,
          `language` String DEFAULT '',
          `suggestions_size_sum` UInt32 DEFAULT 0,
          `occurrences` UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, date, user_id, event, language)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW code_suggestion_daily_events_mv TO code_suggestion_daily_events
      (
          `user_id` UInt64,
          `date` Date,
          `event` UInt8,
          `occurrences` UInt8
      )
      AS SELECT
          user_id,
          toDate(timestamp) AS date,
          event,
          1 AS occurrences
      FROM code_suggestion_usages
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW code_suggestion_daily_events_mv_new TO code_suggestion_daily_events_new
      (
          `namespace_path` String,
          `user_id` UInt64,
          `date` Date,
          `event` UInt8,
          `language` LowCardinality(String),
          `suggestions_size_sum` UInt64,
          `occurrences` UInt8
      )
      AS SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          language,
          suggestion_size AS suggestions_size_sum,
          1 AS occurrences
      FROM code_suggestion_usages
    SQL
  end
end
