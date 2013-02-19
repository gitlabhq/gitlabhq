class RenameStateToMergeStatusInMilestone < ActiveRecord::Migration
  def change
    rename_column :merge_requests, :state, :merge_status
  end
end
