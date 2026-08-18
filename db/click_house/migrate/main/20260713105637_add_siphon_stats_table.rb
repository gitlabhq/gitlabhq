# frozen_string_literal: true

class AddSiphonStatsTable < ClickHouse::Migration
  def up
    execute <<-SQL
      CREATE TABLE IF NOT EXISTS siphon_internal_events
      (
        uuid UUID,
        stream_identifier LowCardinality(String),
        producer_application_identifier LowCardinality(String),
        consumer_application_identifier LowCardinality(String),
        postgresql_schema LowCardinality(String),
        postgresql_table LowCardinality(String),
        timestamp DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC') CODEC(Delta, ZSTD),
        produced_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD),
        consumed_at DateTime64(6, 'UTC') CODEC(Delta, ZSTD),
        package_events_count UInt64,
        package_size_in_bytes UInt64,
        event_type UInt8,
        version DateTime64(6, 'UTC') DEFAULT now64(6, 'UTC'),
        deleted Bool DEFAULT FALSE
      )
      ENGINE = ReplacingMergeTree(version, deleted)
      PRIMARY KEY (postgresql_schema, postgresql_table, timestamp, uuid)
      PARTITION BY toYYYYMM(timestamp)
      TTL timestamp + INTERVAL 12 MONTH;
    SQL
  end

  def down
    execute <<-SQL
      DROP TABLE IF EXISTS siphon_internal_events
    SQL
  end
end
