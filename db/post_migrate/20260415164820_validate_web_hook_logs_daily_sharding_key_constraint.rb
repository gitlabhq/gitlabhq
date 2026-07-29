# frozen_string_literal: true

class ValidateWebHookLogsDailyShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def up
    # no-op: validating check_19dc80d658 fails with PG::CheckViolation on orphan
    # web_hook_logs_daily rows (all sharding keys NULL) during fast chained upgrades,
    # before the table's 14-day partition rollover clears them. The constraint is left
    # NOT VALID here (still enforced on new writes) and re-validated after orphan cleanup
    # in a later migration.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/603303
  end

  def down
    # no-op
  end
end
