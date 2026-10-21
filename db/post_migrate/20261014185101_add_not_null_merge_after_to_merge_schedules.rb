# frozen_string_literal: true

class AddNotNullMergeAfterToMergeSchedules < Gitlab::Database::Migration[2.4]
  disable_ddl_transaction!

  milestone '19.6'

  def up
    add_not_null_constraint :merge_request_merge_schedules, :merge_after, validate: false
  end

  def down
    remove_not_null_constraint :merge_request_merge_schedules, :merge_after
  end
end
