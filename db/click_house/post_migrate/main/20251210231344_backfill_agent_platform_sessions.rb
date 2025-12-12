# frozen_string_literal: true

class BackfillAgentPlatformSessions < ClickHouse::Migration
  def up
    start_date = Date.new(2025, 1, 1)
    end_date = Time.zone.today

    current_date = start_date

    while current_date < end_date
      next_date = current_date + 1.month

      execute <<~SQL
        INSERT INTO agent_platform_sessions
        SELECT
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
        WHERE (event IN (8, 9, 19, 20, 21, 22))
          AND (JSONExtractString(extras, 'session_id') != '')
          AND timestamp >= toDateTime('#{current_date.strftime('%Y-%m-%d 00:00:00')}')
          AND timestamp < toDateTime('#{next_date.strftime('%Y-%m-%d 00:00:00')}')
        GROUP BY
          namespace_path,
          user_id,
          session_id,
          flow_type,
          project_id,
          environment,
          toYear(timestamp)
      SQL

      current_date = next_date
    end
  end

  def down
    # Backfill is not reversible
  end
end
