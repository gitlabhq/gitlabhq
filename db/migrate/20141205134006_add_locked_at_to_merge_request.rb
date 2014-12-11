class AddLockedAtToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :locked_at, :datetime
  end
end
