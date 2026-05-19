# frozen_string_literal: true

# Removes the legacy code_suggestion_events_daily_new table and its materialized view
# now that the table swap in 20260429185701_swap_code_suggestion_events_daily_tables.rb
# has promoted code_suggestion_events_daily as the primary table with ide_name support.
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/580851
class DropCodeSuggestionEventsDailyNew < ClickHouse::Migration
  def up
    execute <<~SQL
      DROP VIEW IF EXISTS code_suggestion_events_daily_new_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS code_suggestion_events_daily_new
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS code_suggestion_events_daily_new
      (
          namespace_path String DEFAULT '0/',
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
      CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_events_daily_new_mv
      TO code_suggestion_events_daily_new
      AS SELECT
          namespace_path AS namespace_path,
          user_id AS user_id,
          toDate(timestamp) AS date,
          event AS event,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL
  end
end
