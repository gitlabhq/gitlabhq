class RemovePositionFromIssuables < ActiveRecord::Migration
  DOWNTIME = false

  def change
    remove_column :issues, :position, :integer
    remove_column :merge_requests, :position, :integer
  end
end
