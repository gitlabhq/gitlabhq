class ChangeStateTypeInMergeRequest < ActiveRecord::Migration
  def up
    change_column :merge_requests, :state, :string
  end

  def down
    change_column :merge_requests, :state, :boolean
  end
end
