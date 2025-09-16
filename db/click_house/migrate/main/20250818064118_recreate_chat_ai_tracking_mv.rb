# frozen_string_literal: true

class RecreateChatAiTrackingMv < ClickHouse::Migration
  def up
    execute <<-SQL
      ALTER TABLE duo_chat_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          1 AS occurrences
      FROM ai_usage_events WHERE event=6
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE duo_chat_events_daily_mv MODIFY QUERY
      SELECT
          namespace_path,
          user_id,
          toDate(timestamp) AS date,
          event,
          1 AS occurrences
      FROM duo_chat_events;
    SQL
  end
end
