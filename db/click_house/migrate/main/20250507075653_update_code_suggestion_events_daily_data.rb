# frozen_string_literal: true

class UpdateCodeSuggestionEventsDailyData < ClickHouse::Migration
  def up
    execute("CREATE TABLE IF NOT EXISTS code_suggestion_events_daily_temp AS code_suggestion_events_daily")

    execute("TRUNCATE TABLE code_suggestion_events_daily_temp")

    execute(<<~SQL
      INSERT INTO code_suggestion_events_daily_temp
      SELECT * FROM (
            SELECT
                namespace_path,
                user_id,
                toDate(timestamp) as date,
                event,
                language,
                SUM(suggestion_size) as suggestions_size_sum,
                COUNT(*) as occurrences
            FROM code_suggestion_events
            GROUP BY namespace_path, user_id, date, event, language
      ) fresh_data WHERE occurrences <> 0 OR suggestions_size_sum <> 0;
    SQL
           )
    execute("EXCHANGE TABLES code_suggestion_events_daily AND code_suggestion_events_daily_temp")
    execute("DROP TABLE code_suggestion_events_daily_temp")
  end

  def down
    # no-op
  end
end
