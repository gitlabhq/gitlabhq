# frozen_string_literal: true

class AddMergeRequestDiffsProjectIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'index_merge_request_diffs_on_project_id'

  def up
    add_concurrent_index :merge_request_diffs, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :merge_request_diffs, name: INDEX_NAME
  end
end
