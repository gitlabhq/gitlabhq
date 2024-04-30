# frozen_string_literal: true

class DropIdxMergeRequestsOnTargetProjectIdAndLockedState < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  INDEX_NAME = 'idx_merge_requests_on_target_project_id_and_locked_state'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end

  def down
    add_concurrent_index :merge_requests, :target_project_id, where: 'state_id = 4', name: INDEX_NAME
  end
end
