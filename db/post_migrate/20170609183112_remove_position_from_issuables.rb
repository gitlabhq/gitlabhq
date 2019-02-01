class RemovePositionFromIssuables < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def change
    remove_column :issues, :position, :integer
    remove_column :merge_requests, :position, :integer
  end
end
