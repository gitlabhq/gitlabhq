# rubocop:disable all
class AddNewMergeStatusToMergeRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :merge_requests, :new_merge_status, :string
  end
end
