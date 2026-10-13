# frozen_string_literal: true

class FixMergeRequestsBaseTtl < ClickHouse::Migration
  def up
    execute <<~SQL
      ALTER TABLE merge_requests_base
      MODIFY TTL toDateTime(seen) + INTERVAL 1 HOUR
      SETTINGS materialize_ttl_after_modify = 0
    SQL
  end

  def down
    # No-op: reverting the TTL expression would break supported ClickHouse 25.x versions.
  end
end
