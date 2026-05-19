# frozen_string_literal: true

class ValidateWebHookLogsDailyShardingKeyConstraint < Gitlab::Database::Migration[2.3]
  CONSTRAINT_NAME = 'check_19dc80d658'

  milestone '19.0'

  def up
    validate_multi_column_not_null_constraint :web_hook_logs_daily,
      :organization_id, :group_id, :project_id,
      constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
