# frozen_string_literal: true

class AddMergeAfterIndexToMergeSchedules < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  INDEX_NAME = 'index_merge_request_merge_schedules_on_merge_after_and_mr_id'

  def up
    add_concurrent_index :merge_request_merge_schedules, %i[merge_after merge_request_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_merge_schedules, INDEX_NAME
  end
end
