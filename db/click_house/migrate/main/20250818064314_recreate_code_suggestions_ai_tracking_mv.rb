# frozen_string_literal: true

class RecreateCodeSuggestionsAiTrackingMv < ClickHouse::Migration
  def up
    execute <<-SQL
      ALTER TABLE code_suggestion_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          toLowCardinality(JSONExtractString(extras, 'language')) AS language,
          JSONExtractUInt(extras, 'suggestion_size') AS suggestions_size_sum,
          1 AS occurrences
      FROM ai_usage_events WHERE event IN (1,2,3,4,5);
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE code_suggestion_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          language,
          suggestion_size AS suggestions_size_sum,
          1 AS occurrences
      FROM code_suggestion_events;
    SQL
  end
end
