class AddCommitsDiffStoreToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :st_commits, :text, :null => true
    add_column :merge_requests, :st_diffs, :text, :null => true
  end
end
