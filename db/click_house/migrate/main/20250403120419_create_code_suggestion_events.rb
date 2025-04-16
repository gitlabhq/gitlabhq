# frozen_string_literal: true

class CreateCodeSuggestionEvents < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_events
        (
          user_id UInt64 DEFAULT 0,
          event UInt8 DEFAULT 0,
          timestamp DateTime64(6, 'UTC') DEFAULT now64(),
          namespace_path String DEFAULT '0/',
          unique_tracking_id String DEFAULT '',
          language LowCardinality(String) DEFAULT '',
          suggestion_size UInt64 DEFAULT 0,
          branch_name String DEFAULT ''
        ) ENGINE = ReplacingMergeTree
        PARTITION BY toYear(timestamp)
        ORDER BY (namespace_path, user_id, event, timestamp)
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_events_daily
      (
        namespace_path DEFAULT '0/',
        user_id UInt64 DEFAULT 0,
        date Date32 DEFAULT toDate(now64()),
        event UInt8 DEFAULT 0,
        language String DEFAULT '',
        suggestions_size_sum UInt32 DEFAULT 0,
        occurrences UInt64 DEFAULT 0
      ) ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, date, user_id, event, language)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_events_daily_mv
      TO code_suggestion_events_daily
      AS
      SELECT
        namespace_path,
        user_id,
        toDate(timestamp) as date,
        event,
        language,
        suggestion_size as suggestions_size_sum,
        1 as occurrences
      FROM code_suggestion_events
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_events_daily_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_events_daily
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_events
    SQL
  end
end
