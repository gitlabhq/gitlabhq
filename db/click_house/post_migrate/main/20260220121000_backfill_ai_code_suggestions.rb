# frozen_string_literal: true

class BackfillAiCodeSuggestions < ClickHouse::Migration
  BACKFILL_QUERY = <<~SQL
    INSERT INTO ai_code_suggestions
    SELECT
      JSONExtractString(e.extras, 'unique_tracking_id') AS uid,
      e.namespace_path,
      e.user_id,
      min(e.timestamp) AS timestamp,
      minIfState(toNullable(e.timestamp), event = 2) AS shown_at,
      maxIfState(toNullable(e.timestamp), event = 3) AS accepted_at,
      maxIfState(toNullable(e.timestamp), event = 4) AS rejected_at,
      any(JSONExtractString(e.extras, 'language')) AS language,
      any(JSONExtractString(e.extras, 'branch_name')) AS branch_name,
      any(JSONExtractString(e.extras, 'ide_name')) AS ide_name,
      any(JSONExtractString(e.extras, 'ide_vendor')) AS ide_vendor,
      any(JSONExtractString(e.extras, 'ide_version')) AS ide_version,
      any(JSONExtractString(e.extras, 'extension_name')) AS extension_name,
      any(JSONExtractString(e.extras, 'extension_version')) AS extension_version,
      any(JSONExtractString(e.extras, 'language_server_version')) AS language_server_version,
      any(JSONExtractString(e.extras, 'model_name')) AS model_name,
      any(JSONExtractString(e.extras, 'model_engine')) AS model_engine,
      max(JSONExtractUInt(e.extras, 'suggestion_size')) AS suggestion_size
    FROM ai_usage_events e
    WHERE event IN (2, 3, 4)
  SQL

  def up
    from = get_min_timestamp
    return unless from

    from = from.beginning_of_month
    to = DateTime.current.end_of_month + 1.month

    each_week(from, to) do |week_start, week_end|
      execute(query_for(week_start, week_end))
    end

    # Handle any remaining data after the last week
    execute(query_for(to, nil))
  end

  def down
    # Data migration - no rollback needed
  end

  private

  def get_min_timestamp
    result = connection.select(<<~SQL).first.fetch("min_timestamp", nil)
      SELECT minOrNull(timestamp) as min_timestamp
      FROM ai_usage_events
      WHERE event IN (2, 3, 4)
    SQL
    result ? DateTime.parse(result.to_s) : nil
  end

  def each_week(from, to)
    current = from
    while current <= to
      yield(current, [current + 1.week, to].min)
      current += 1.week
    end
  end

  def query_for(week_start, week_end = nil)
    full_query = "#{BACKFILL_QUERY} AND e.timestamp >= %{start}"
    full_query += " AND e.timestamp < %{end}" if week_end
    full_query += " GROUP BY ALL"

    params = { start: week_start.to_f }
    params[:end] = week_end.to_f if week_end
    full_query % params
  end
end
