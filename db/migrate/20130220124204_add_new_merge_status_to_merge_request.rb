class AddNewMergeStatusToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :new_merge_status, :string
  end
end
