# frozen_string_literal: true

class CreateCodeSuggestionEventsDailyNew < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_events_daily_new
      (
          namespace_path String DEFAULT '0/',
          user_id UInt64 DEFAULT 0,
          date Date32 DEFAULT toDate(now64()),
          event UInt8 DEFAULT 0,
          ide_name LowCardinality(String) DEFAULT '',
          language LowCardinality(String) DEFAULT '',
          suggestions_size_sum UInt32 DEFAULT 0,
          occurrences UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, date, user_id, event, ide_name, language)
      SETTINGS index_granularity = 64;
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS code_suggestion_events_daily_new
    SQL
  end
end
