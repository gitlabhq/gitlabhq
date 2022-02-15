# frozen_string_literal: true

class AddIndexToMergeRequestAssigneesState < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_on_merge_request_assignees_state'

  def up
    add_concurrent_index :merge_request_assignees, :state, where: 'state = 2', name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_assignees, INDEX_NAME
  end
end
