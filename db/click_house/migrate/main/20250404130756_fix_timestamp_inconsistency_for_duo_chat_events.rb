# frozen_string_literal: true

class FixTimestampInconsistencyForDuoChatEvents < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS duo_chat_events_backup
      (
        user_id UInt64 DEFAULT 0,
        event UInt8 DEFAULT 0,
        namespace_path String DEFAULT '0/',
        timestamp DateTime64(6, 'UTC') DEFAULT now64()
      ) ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (namespace_path, user_id, event, timestamp)
    SQL
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS duo_chat_events_daily
      (
        namespace_path DEFAULT '0/',
        user_id UInt64 DEFAULT 0,
        date Date32 DEFAULT toDate(now64()),
        event UInt8 DEFAULT 0,
        occurrences UInt64 DEFAULT 0,
      ) ENGINE = SummingMergeTree
      PARTITION BY toYear(date)
      ORDER BY (namespace_path, user_id, date, event)
      SETTINGS index_granularity = 64
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS duo_chat_events_daily_mv
      TO duo_chat_events_daily
      AS
      SELECT
        namespace_path,
        user_id,
        toDate(timestamp) as date,
        event,
        1 as occurrences
      FROM duo_chat_events
    SQL

    execute <<~SQL
      DROP VIEW IF EXISTS duo_chat_daily_events_mv
    SQL

    execute <<~SQL
      EXCHANGE TABLES duo_chat_events_backup AND duo_chat_events
    SQL

    execute <<~SQL
      INSERT INTO duo_chat_events(user_id, event, timestamp, namespace_path)
      SELECT
          user_id, event,
          CASE WHEN r5 = r3 THEN r3 ELSE floor(toFloat64(orig_timestamp), 3) END as timestamp,
          namespace_path
      FROM (
               SELECT user_id, event,
                      round(toFloat64(timestamp),5) as r5,
                      round(toFloat64(timestamp),3) as r3,
                      timestamp as orig_timestamp,
                      namespace_path
               FROM duo_chat_events_backup)
    SQL
  end

  def down
    # swap back and remove backup
    execute <<~SQL
      EXCHANGE TABLES duo_chat_events_backup AND duo_chat_events
    SQL

    execute <<~SQL
      DROP VIEW IF EXISTS duo_chat_events_daily_mv
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS duo_chat_events_daily
    SQL

    execute <<~SQL
      DROP TABLE IF EXISTS duo_chat_events_backup
    SQL
  end
end
