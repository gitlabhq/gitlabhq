# rubocop:disable all
class RemoveMergeStatusFromMergeRequest < ActiveRecord::Migration[4.2]
  def up
    remove_column :merge_requests, :merge_status
  end

  def down
    add_column :merge_requests, :merge_status, :integer
  end
end
