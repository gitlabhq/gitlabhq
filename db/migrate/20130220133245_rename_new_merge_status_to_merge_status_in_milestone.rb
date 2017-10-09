# rubocop:disable all
class RenameNewMergeStatusToMergeStatusInMilestone < ActiveRecord::Migration[4.2]
  def change
    rename_column :merge_requests, :new_merge_status, :merge_status
  end
end
