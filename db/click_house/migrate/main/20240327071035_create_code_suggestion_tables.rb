# frozen_string_literal: true

class CreateCodeSuggestionTables < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_usages
      (
        user_id UInt64 DEFAULT 0,
        event UInt8 DEFAULT 0,
        namespace_path String DEFAULT '0/',
        timestamp DateTime64(6, 'UTC') DEFAULT now64()
      ) ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, event, timestamp)
    SQL

    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_daily_usages
      (
        user_id UInt64 DEFAULT 0,
        timestamp Date32 DEFAULT toDate(now64()),
      ) ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, timestamp)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_daily_usages_mv
      TO code_suggestion_daily_usages
      AS
      SELECT
        user_id,
        timestamp
      FROM code_suggestion_usages
      WHERE event = 1
      GROUP BY user_id, timestamp
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_daily_usages_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_daily_usages
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_usages
    SQL
  end
end
