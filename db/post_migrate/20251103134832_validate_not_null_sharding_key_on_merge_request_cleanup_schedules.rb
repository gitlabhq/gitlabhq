# frozen_string_literal: true

class ValidateNotNullShardingKeyOnMergeRequestCleanupSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = :check_8ac5179c82

  def up
    validate_not_null_constraint :merge_request_cleanup_schedules, :project_id, constraint_name: CONSTRAINT_NAME
  end

  def down
    # no-op
  end
end
