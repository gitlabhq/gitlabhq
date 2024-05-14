# frozen_string_literal: true

class DropIndexMergeRequestsOnTargetProjectIdAndIidAndStateId < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  INDEX_NAME = 'index_merge_requests_on_target_project_id_and_iid_and_state_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, %i[target_project_id iid state_id], name: INDEX_NAME
  end
end
