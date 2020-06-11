# frozen_string_literal: true

class AddPartialIndexOnLockedStateIdToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = "idx_merge_requests_on_target_project_id_and_locked_state"
  LOCKED_STATE_ID = 4

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, :target_project_id, where: "(state_id = #{LOCKED_STATE_ID})", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, name: INDEX_NAME
  end
end
