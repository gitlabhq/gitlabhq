class AddMilestoneIdToBoards < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :boards, :milestone_id, :integer, null: true
  end
end
