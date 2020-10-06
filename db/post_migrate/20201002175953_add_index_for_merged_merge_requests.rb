# frozen_string_literal: true

class AddIndexForMergedMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'idx_merge_requests_on_merged_state'

  disable_ddl_transaction!

  def up
    add_concurrent_index :merge_requests,
                         :id,
                         where: 'state_id = 3',
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_requests, INDEX_NAME
  end
end
