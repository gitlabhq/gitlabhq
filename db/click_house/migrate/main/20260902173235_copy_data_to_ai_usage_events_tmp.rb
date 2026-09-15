# frozen_string_literal: true

class CopyDataToAiUsageEventsTmp < ClickHouse::Migration
  COLUMNS = %w[user_id event timestamp namespace_path traversal_path extras].freeze

  # Rows predating the dual write carry the `'0/'` DEFAULT sentinel and are resolved from the leaf
  # namespace id, which is the last path component in both the legacy (`9/42/`) and the org-scoped
  # (`7/9/42/`) format. That leaf is a group or a project namespace, and `siphon_namespaces` feeds
  # both into the dictionary. Already resolved rows pass through untouched, which makes the transform
  # idempotent and safe to re-run over the tail window before the swap.
  #
  # The dictionary is fed by Siphon, so it resolves nothing on installations that do not run it.
  # Those rows keep the sentinel rather than falling back to `namespace_path`: a legacy path in the
  # org-scoped sort key would be indistinguishable from a real one and impossible to backfill later.
  TRAVERSAL_PATH_EXPRESSION = <<~SQL.squish
    if(traversal_path != '0/',
      traversal_path,
      dictGetOrDefault(
        'namespace_traversal_paths_dict',
        'traversal_path',
        toUInt64OrZero(splitByChar('/', namespace_path)[-2]),
        '0/'
      )
    ) AS traversal_path
  SQL

  SELECT_EXPRESSIONS = COLUMNS.map do |column|
    column == 'traversal_path' ? TRAVERSAL_PATH_EXPRESSION : column
  end.freeze

  def up
    from = min_timestamp
    return unless from

    # One INSERT per monthly partition to bound peak memory.
    each_month(from.beginning_of_month, DateTime.current.end_of_month) do |month_start, month_end|
      execute(<<~SQL)
        INSERT INTO ai_usage_events_tmp (#{COLUMNS.join(', ')})
        SELECT #{SELECT_EXPRESSIONS.join(', ')}
        FROM ai_usage_events
        WHERE timestamp >= #{month_start.to_f} AND timestamp < #{month_end.to_f}
      SQL
    end
  end

  def down
    execute 'TRUNCATE TABLE IF EXISTS ai_usage_events_tmp'
  end

  private

  def min_timestamp
    result = connection.select(<<~SQL).first.fetch('min_timestamp', nil)
      SELECT minOrNull(timestamp) AS min_timestamp FROM ai_usage_events
    SQL

    result ? DateTime.parse(result.to_s) : nil
  end

  def each_month(from, to)
    current = from
    while current < to
      next_month = current + 1.month
      yield(current, next_month)
      current = next_month
    end
  end
end
