# frozen_string_literal: true

class PrepareAsyncConstraintOnProtectedBranchPushAccessLevelsShardingKey < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_2b64375289'
  TABLE_NAME = :protected_branch_push_access_levels

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
