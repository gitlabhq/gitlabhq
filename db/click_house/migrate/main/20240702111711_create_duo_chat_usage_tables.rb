# frozen_string_literal: true

class CreateDuoChatUsageTables < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS duo_chat_daily_events
      (
        user_id UInt64 DEFAULT 0,
        date Date32 DEFAULT toDate(now64()),
        event UInt8 DEFAULT 0,
        occurrences UInt64 DEFAULT 0,
      ) ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (user_id, date, event)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS duo_chat_daily_events_mv
      TO duo_chat_daily_events
      AS
      SELECT
        user_id,
        toDate(timestamp) as date,
        event,
        1 as occurrences
      FROM duo_chat_events
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS duo_chat_daily_events_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS duo_chat_daily_events
    SQL
  end
end
