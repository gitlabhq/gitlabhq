# frozen_string_literal: true

class CreateEventAuthorsTable < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS event_authors
      (
        author_id UInt64 DEFAULT 0,
        deleted UInt8 DEFAULT 0,
        last_event_at DateTime64(6, 'UTC') DEFAULT now64()
      )
      ENGINE = ReplacingMergeTree(last_event_at, deleted)
      PRIMARY KEY (author_id)
      ORDER BY (author_id)
    SQL
  end

  def down
    execute <<~SQL
      DROP TABLE IF EXISTS event_authors
    SQL
  end
end
