# frozen_string_literal: true

class BackfillNewCodeSuggestionDailyEvents < ClickHouse::Migration
  def up
    execute <<~SQL
      INSERT INTO code_suggestion_daily_events_new
      (
          namespace_path,
          user_id,
          date,
          event,
          language,
          suggestions_size_sum,
          occurrences
      )
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          language,
          sum(suggestion_size) AS suggestions_size_sum,
          count() AS occurrences
      FROM code_suggestion_usages
      GROUP BY
          namespace_path,
          user_id,
          toDate(timestamp),
          event,
          language
    SQL
  end

  def down
    # NO OP
  end
end
