class AddAutomergeToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :state, :integer, :null => false, :default => 1
  end
end
