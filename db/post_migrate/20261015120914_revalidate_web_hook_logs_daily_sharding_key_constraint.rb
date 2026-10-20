# frozen_string_literal: true

class RevalidateWebHookLogsDailyShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.6'

  CONSTRAINT_NAME = 'check_19dc80d658'

  def up
    # Validates check_19dc80d658, which ValidateWebHookLogsDailyShardingKeyConstraint (19.0) left
    # NOT VALID on self-managed. Orphan rows are removed first by
    # CleanupWebHookLogsDailyShardingKeyOrphans (queued in 19.3, finalized by the preceding
    # migration on self-managed). On GitLab.com the original 19.0 migration validated it before it
    # was made a no-op, so this is a cheap no-op there.
    # See https://gitlab.com/gitlab-org/gitlab/-/work_items/603303
    validate_multi_column_not_null_constraint :web_hook_logs_daily,
      :organization_id, :group_id, :project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
