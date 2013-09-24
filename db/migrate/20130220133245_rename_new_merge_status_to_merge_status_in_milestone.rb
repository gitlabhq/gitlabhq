class RenameNewMergeStatusToMergeStatusInMilestone < ActiveRecord::Migration
  def change
    rename_column :merge_requests, :new_merge_status, :merge_status
  end
end
