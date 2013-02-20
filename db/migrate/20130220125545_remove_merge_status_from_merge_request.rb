class RemoveMergeStatusFromMergeRequest < ActiveRecord::Migration
  def up
    remove_column :merge_requests, :merge_status
  end

  def down
    add_column :merge_requests, :merge_status, :integer
  end
end
