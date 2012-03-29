class AddAutomergeToMergeRequest < ActiveRecord::Migration
  def change
    add_column :merge_requests, :auto_merge, :boolean, :null => false, :default => true

  end
end
