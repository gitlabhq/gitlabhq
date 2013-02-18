class ChangeStateTypeInMilestone < ActiveRecord::Migration
  def up
    change_column :milestones, :state, :string
  end

  def down
    change_column :milestones, :state, :boolean
  end
end
