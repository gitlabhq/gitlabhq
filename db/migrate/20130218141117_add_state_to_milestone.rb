class AddStateToMilestone < ActiveRecord::Migration
  def change
    add_column :milestones, :state, :string
  end
end
