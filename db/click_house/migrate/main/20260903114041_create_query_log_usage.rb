# frozen_string_literal: true

class CreateQueryLogUsage < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE IF NOT EXISTS query_log_usage
      (
        event_time DateTime64(6, 'UTC') CODEC(Delta(8), ZSTD(1)),
        query_id String CODEC(ZSTD(1)),
        root_namespace_id Int64 CODEC(ZSTD(1)),
        organization_id Int64 CODEC(ZSTD(1)),
        user_id Int64 CODEC(ZSTD(1)),
        correlation_id String CODEC(ZSTD(1)),
        application LowCardinality(String),
        feature_category LowCardinality(String),
        query_kind LowCardinality(String),
        databases Array(LowCardinality(String)),
        tables Array(LowCardinality(String)),
        query_duration_ms Int64 CODEC(ZSTD(1)),
        read_rows Int64 CODEC(ZSTD(1)),
        read_bytes Int64 CODEC(ZSTD(1)),
        written_rows Int64 CODEC(ZSTD(1)),
        written_bytes Int64 CODEC(ZSTD(1)),
        memory_usage_bytes Int64 CODEC(ZSTD(1)),
        os_cpu_virtual_time_us Int64 CODEC(ZSTD(1)),
        exception_code Int64 CODEC(ZSTD(1)),
        log_comment String CODEC(ZSTD(1)),
        vcpu_seconds Float64 ALIAS os_cpu_virtual_time_us / 1000000,
        -- toFloat64 first: the Int64 product overflows past ~9.2e18 and wraps negative
        memory_gb_seconds Float64 ALIAS (toFloat64(memory_usage_bytes) * query_duration_ms) / 1000000000000
      )
      ENGINE = MergeTree
      PARTITION BY toYYYYMM(event_time)
      ORDER BY (event_time, query_id)
      TTL event_time + INTERVAL 3 MONTH
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS query_log_usage'
  end
end
