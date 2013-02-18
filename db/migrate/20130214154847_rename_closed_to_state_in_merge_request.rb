class RenameClosedToStateInMergeRequest < ActiveRecord::Migration
  def change
    rename_column :merge_requests, :closed, :state
  end
end
