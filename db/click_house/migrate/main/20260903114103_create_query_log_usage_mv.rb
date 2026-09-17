# frozen_string_literal: true

class CreateQueryLogUsageMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE MATERIALIZED VIEW IF NOT EXISTS query_log_usage_mv TO query_log_usage
      AS SELECT
        event_time_microseconds AS event_time,
        query_id,
        assumeNotNull(JSONExtract(log_comment, 'root_namespace_id', 'Nullable(Int64)')) AS root_namespace_id,
        JSONExtract(log_comment, 'organization_id', 'Int64') AS organization_id,
        JSONExtract(log_comment, 'user_id', 'Int64') AS user_id,
        JSONExtractString(log_comment, 'correlation_id') AS correlation_id,
        JSONExtractString(log_comment, 'application') AS application,
        JSONExtractString(log_comment, 'feature_category') AS feature_category,
        query_kind,
        databases,
        tables,
        query_duration_ms,
        read_rows,
        read_bytes,
        written_rows,
        written_bytes,
        memory_usage AS memory_usage_bytes,
        ProfileEvents['OSCPUVirtualTimeMicroseconds'] AS os_cpu_virtual_time_us,
        exception_code,
        log_comment
      FROM system.query_log
      WHERE type != 'QueryStart'
        -- An async insert also logs an AsyncInsertFlush row whose cost covers the
        -- whole flushed batch but carries only one query's log_comment. Keeping it
        -- would double count the Insert and bill the batch to one arbitrary namespace.
        AND query_kind != 'AsyncInsertFlush'
        AND log_comment LIKE '{%'
        AND JSONExtract(log_comment, 'root_namespace_id', 'Nullable(Int64)') IS NOT NULL
    SQL
  end

  def down
    execute 'DROP VIEW IF EXISTS query_log_usage_mv'
  end
end
