# frozen_string_literal: true

class BackfillAiUsageEventsDaily < ClickHouse::Migration
  def up
    execute <<-SQL
      TRUNCATE TABLE ai_usage_events_daily
    SQL

    execute <<-SQL
      INSERT INTO ai_usage_events_daily (namespace_path, date, event, user_id, occurrences)
      SELECT
          namespace_path,
          toDate(timestamp) AS date,
          event,
          user_id,
          count() AS occurrences
      FROM ai_usage_events
      GROUP BY namespace_path, date, event, user_id
    SQL
  end

  def down
    # NO-OP
  end
end
