# frozen_string_literal: true

class MigrateAiEventsToAiUsageEvents < ClickHouse::Migration
  CODE_SUGGESTION_QUERY = <<~SQL
    INSERT INTO ai_usage_events
    (user_id, event, timestamp, namespace_path, extras)
    SELECT
      user_id,
      event,
      timestamp,
      namespace_path,
      toJSONString(map(
        'unique_tracking_id', unique_tracking_id,
        'language', language,
        'suggestion_size', suggestion_size,
        'branch_name', branch_name
      )) as extras
    FROM code_suggestion_events
  SQL

  DUO_CHAT_QUERY = <<~SQL
    INSERT INTO ai_usage_events
    (user_id, event, timestamp, namespace_path, extras)
    SELECT
      user_id,
      6 as event,  -- request_duo_chat_response
      timestamp,
      namespace_path,
      toJSONString(map()) as extras
    FROM duo_chat_events
  SQL

  TROUBLESHOOT_JOB_QUERY = <<~SQL
    INSERT INTO ai_usage_events
    (user_id, event, timestamp, namespace_path, extras)
    SELECT
      user_id,
      7 as event,  -- troubleshoot_job
      timestamp,
      namespace_path,
      toJSONString(map(
        'project_id', project_id,
        'job_id', job_id,
        'pipeline_id', pipeline_id,
        'merge_request_id', merge_request_id
      )) as extras
    FROM troubleshoot_job_events
  SQL

  def up
    migrate_events('code_suggestion_events', CODE_SUGGESTION_QUERY)
    migrate_events('duo_chat_events', DUO_CHAT_QUERY)
    migrate_events('troubleshoot_job_events', TROUBLESHOOT_JOB_QUERY)
  end

  def down
    # Data migration - no rollback needed
  end

  private

  def migrate_events(table_name, query)
    from = get_min_timestamp(table_name)
    return unless from

    from = from.beginning_of_month
    to = DateTime.current.end_of_month + 1.month

    each_week(from, to) do |week_start, week_end|
      execute(query_for(query, week_start, week_end))
    end

    # Handle any remaining data after the last week
    execute(query_for(query, to, nil))
  end

  def get_min_timestamp(table_name)
    result = connection.select("SELECT minOrNull(timestamp) as min_timestamp FROM #{table_name}")
                       .first.fetch("min_timestamp", nil)
    result ? DateTime.parse(result.to_s) : nil
  end

  def each_week(from, to)
    current = from
    while current <= to
      yield(current, [current + 1.week, to].min)
      current += 1.week
    end
  end

  def query_for(base_query, week_start, week_end = nil)
    full_query = if week_end
                   "#{base_query} WHERE timestamp >= %{start} AND timestamp < %{end}"
                 else
                   "#{base_query} WHERE timestamp >= %{start}"
                 end

    params = { start: week_start.to_f }
    params[:end] = week_end.to_f if week_end
    full_query % params
  end
end
