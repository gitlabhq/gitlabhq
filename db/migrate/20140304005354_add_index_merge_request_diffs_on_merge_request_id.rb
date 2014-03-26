class AddIndexMergeRequestDiffsOnMergeRequestId < ActiveRecord::Migration
  def change
    add_index :merge_request_diffs, :merge_request_id, unique: true
  end
end
