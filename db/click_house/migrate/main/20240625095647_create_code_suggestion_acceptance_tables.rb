# frozen_string_literal: true

class CreateCodeSuggestionAcceptanceTables < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_daily_events
      (
        user_id UInt64 DEFAULT 0,
        date Date32 DEFAULT toDate(now64()),
        event UInt8 DEFAULT 0,
        occurrences UInt64 DEFAULT 0,
      ) ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (user_id, date, event)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_daily_events_mv
      TO code_suggestion_daily_events
      AS
      SELECT
        user_id,
        toDate(timestamp) as date,
        event,
        1 as occurrences
      FROM code_suggestion_usages
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_daily_events_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_daily_events
    SQL
  end
end
