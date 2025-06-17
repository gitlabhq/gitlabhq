# frozen_string_literal: true

class RemoveOldDuoChatTables < ClickHouse::Migration
  def up
    execute "DROP TABLE IF EXISTS duo_chat_events_backup"
  end

  def down
    execute <<~SQL
      CREATE TABLE duo_chat_events_backup
      (
          `user_id` UInt64 DEFAULT 0,
          `event` UInt8 DEFAULT 0,
          `namespace_path` String DEFAULT '0/',
          `timestamp` DateTime64(6, 'UTC') DEFAULT now64()
      )
      ENGINE = ReplacingMergeTree
      PARTITION BY toYear(timestamp)
      ORDER BY (user_id, event, timestamp)
      SETTINGS index_granularity = 8192
    SQL
  end
end
