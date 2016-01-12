class AddIndexMilestonesTitle < ActiveRecord::Migration
  def change
    add_index :milestones, :title
  end
end
