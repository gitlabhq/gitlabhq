# frozen_string_literal: true

class PrepareAsyncCheckNotNullConstraintOnMergeRequestCleanupSchedules < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  CONSTRAINT_NAME = 'check_8ac5179c82'
  TABLE_NAME = :merge_request_cleanup_schedules

  def up
    prepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end

  def down
    unprepare_async_check_constraint_validation TABLE_NAME, name: CONSTRAINT_NAME
  end
end
