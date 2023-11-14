# frozen_string_literal: true

class DropMergeRequestAssigneesOnMergeRequestIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '16.6'

  INDEX_NAME = 'index_merge_request_assignees_on_merge_request_id'
  TABLE_NAME = :merge_request_assignees

  def up
    # Duplicated index. This index is covered by +index_merge_request_assignees_on_merge_request_id_and_user_id+
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end

  def down
    add_concurrent_index TABLE_NAME, :merge_request_id, name: INDEX_NAME
  end
end
