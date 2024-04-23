# frozen_string_literal: true

class RemoveIdxMergeRequestsOnTargetProjectIdAndIidOpened < Gitlab::Database::Migration[2.2]
  milestone '17.0'
  INDEX_NAME = 'idx_merge_requests_on_target_project_id_and_iid_opened'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, %i[target_project_id iid], where: 'state_id = 1', name: INDEX_NAME
  end
end
