# frozen_string_literal: true

class FixSiphonInternalEventsTtl < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE siphon_internal_events
      MODIFY TTL toDateTime(timestamp) + INTERVAL 12 MONTH
      SETTINGS materialize_ttl_after_modify = 0
    SQL
  end

  def down
    # No-op: reverting the TTL expression would break supported ClickHouse 25.x versions.
  end
end
