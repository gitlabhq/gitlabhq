# frozen_string_literal: true

class CreateDuoChatEventsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS duo_chat_events
      (
        user_id UInt64 DEFAULT 0,
        event UInt8 DEFAULT 0,
        namespace_path String DEFAULT '0/',
        timestamp DateTime64(6, 'UTC') DEFAULT now64()
      ) ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, event, timestamp)
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS duo_chat_events
    SQL
  end
end
