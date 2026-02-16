# frozen_string_literal: true

class DropDuoChatDailyEventsTable < ClickHouse::Migration
  def up
    # This table was replaced by duo_chat_events_daily
    # and is no longer in use.
    # Check https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186988
    execute <<~SQL
      DROP TABLE IF EXISTS duo_chat_daily_events
    SQL
  end

  def down
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS duo_chat_daily_events
      (
        user_id UInt64 DEFAULT 0,
        date Date32 DEFAULT toDate(now64()),
        event UInt8 DEFAULT 0,
        occurrences UInt64 DEFAULT 0
      )
      ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (user_id, date, event)
      SETTINGS index_granularity = 64
    SQL
  end
end
