# frozen_string_literal: true

class CreateNewCodeSuggestionDailyEventsTables < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_daily_events_new
      (
          namespace_path DEFAULT '0/',
          user_id UInt64 DEFAULT 0,
          date Date32 DEFAULT toDate(now64()),
          event UInt8 DEFAULT 0,
          language String DEFAULT '',
          suggestions_size_sum UInt32 DEFAULT 0,
          occurrences UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, date, user_id, event, language)
      SETTINGS index_granularity = 64;
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_daily_events_mv_new
      TO code_suggestion_daily_events_new
      AS
      SELECT
        namespace_path,
        user_id,
        toDate(timestamp) as date,
        event,
        language,
        suggestion_size as suggestions_size_sum,
        1 as occurrences
      FROM code_suggestion_usages
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_daily_events_mv_new
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_daily_events_new
    SQL
  end
end
