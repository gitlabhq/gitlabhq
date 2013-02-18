class RenameClosedToStateInMilestone < ActiveRecord::Migration
  def change
    rename_column :milestones, :closed, :state
  end
end
