# rubocop:disable all
class RenameStateToMergeStatusInMilestone < ActiveRecord::Migration[4.2]
  def change
    rename_column :merge_requests, :state, :merge_status
  end
end
