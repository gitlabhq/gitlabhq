class RemoveClosedFromMilestone < ActiveRecord::Migration
  def up
    remove_column :milestones, :closed
  end

  def down
    add_column :milestones, :closed, :boolean
  end
end
