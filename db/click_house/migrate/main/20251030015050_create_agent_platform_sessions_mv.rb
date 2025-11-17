# frozen_string_literal: true

class CreateAgentPlatformSessionsMv < ClickHouse::Migration
  def up
    execute <<~SQL
      CREATE TABLE agent_platform_sessions
      (
          `user_id` UInt64,
          `namespace_path` String,
          `project_id` UInt64,
          `session_id` UInt64,
          `flow_type` String,
          `environment` String,
          `session_year` UInt16,

          -- Event agent_platform_session_created/8
          `created_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          -- Event agent_platform_session_started/9
          `started_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          -- Event agent_platform_session_finished/19
          `finished_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          -- Event agent_platform_session_finished/20
          `dropped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          -- Event agent_platform_session_finished/21
          `stopped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          -- Event agent_platform_session_resumed/22
          `resumed_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8)
      )
      ENGINE = AggregatingMergeTree
      PARTITION BY session_year
      ORDER BY (namespace_path, user_id, session_id, flow_type);
    SQL

    execute <<~SQL
      CREATE MATERIALIZED VIEW agent_platform_sessions_mv TO agent_platform_sessions
      (
          `user_id` UInt64,
          `namespace_path` String,
          `project_id` String,
          `session_id` String,
          `flow_type` String,
          `environment` String,
          `created_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          `started_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          `finished_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          `dropped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          `stopped_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8),
          `resumed_event_at` AggregateFunction(anyIf, Nullable(DateTime64(6, 'UTC')), UInt8)
      )
      AS SELECT
          user_id,
          namespace_path,
          JSONExtractUInt(extras, 'project_id') AS project_id,
          JSONExtractUInt(extras, 'session_id') AS session_id,
          JSONExtractString(extras, 'flow_type') AS flow_type,
          JSONExtractString(extras, 'environment') AS environment,
          toYear(timestamp) AS session_year,
          anyIfState(toNullable(timestamp), event = 8) AS created_event_at,
          anyIfState(toNullable(timestamp), event = 9) AS started_event_at,
          anyIfState(toNullable(timestamp), event = 19) AS finished_event_at,
          anyIfState(toNullable(timestamp), event = 20) AS dropped_event_at,
          anyIfState(toNullable(timestamp), event = 21) AS stopped_event_at,
          anyIfState(toNullable(timestamp), event = 22) AS resumed_event_at
      FROM ai_usage_events
      WHERE (event IN (8, 9, 19, 20, 21, 22)) AND (JSONExtractString(extras, 'session_id') != '')
      GROUP BY
          namespace_path,
          user_id,
          session_id,
          flow_type,
          project_id,
          environment,
          toYear(timestamp);
    SQL
  end

  def down
    execute <<~SQL
      DROP VIEW IF EXISTS agent_platform_sessions_mv
    SQL
    execute <<~SQL
      DROP TABLE IF EXISTS agent_platform_sessions
    SQL
  end
end
