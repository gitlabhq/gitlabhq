# frozen_string_literal: true

class DropDuoChatEventsDailyMv < ClickHouse::Migration
  def up
    execute <<-SQL
      DROP VIEW IF EXISTS duo_chat_events_daily_mv
    SQL
  end

  def down
    execute <<-SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS duo_chat_events_daily_mv TO duo_chat_events_daily
      AS SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          1 AS occurrences
      FROM ai_usage_events
      WHERE event = 6
    SQL
  end
end
