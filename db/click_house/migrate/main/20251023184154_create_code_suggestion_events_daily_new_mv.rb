# frozen_string_literal: true

class CreateCodeSuggestionEventsDailyNewMv < ClickHouse::Migration
  def up
    execute <<-SQL
     CREATE MATERIALIZED VIEW IF NOT EXISTS code_suggestion_events_daily_new_mv
     TO code_suggestion_events_daily_new
     AS SELECT
          namespace_path AS namespace_path,
          user_id AS user_id,
          toDate(timestamp) AS date,
          event AS event,
          toLowCardinality(JSONExtractString(extras, 'ide_name')) AS ide_name,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event IN (1, 2, 3, 4, 5);
    SQL
  end

  def down
    execute <<-SQL
      DROP VIEW IF EXISTS code_suggestion_events_daily_new_mv
    SQL
  end
end
