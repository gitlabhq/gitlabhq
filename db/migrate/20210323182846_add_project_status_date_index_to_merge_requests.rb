# frozen_string_literal: true

class AddProjectStatusDateIndexToMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = "idx_mrs_on_target_id_and_created_at_and_state_id"

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests, %i[target_project_id state_id created_at id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
