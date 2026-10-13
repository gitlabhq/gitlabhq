# frozen_string_literal: true

class FixQueryLogUsageTtl < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE query_log_usage
      MODIFY TTL toDateTime(event_time) + INTERVAL 3 MONTH
      SETTINGS materialize_ttl_after_modify = 0
    SQL
  end

  def down
    # No-op: reverting the TTL expression would break supported ClickHouse 25.x versions.
  end
end
