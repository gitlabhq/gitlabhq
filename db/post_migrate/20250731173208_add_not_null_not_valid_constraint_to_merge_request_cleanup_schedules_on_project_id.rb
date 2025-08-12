# frozen_string_literal: true

class AddNotNullNotValidConstraintToMergeRequestCleanupSchedulesOnProjectId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.3'

  def up
    add_not_null_constraint :merge_request_cleanup_schedules, :project_id, validate: false
  end

  def down
    remove_not_null_constraint :merge_request_cleanup_schedules, :project_id
  end
end
