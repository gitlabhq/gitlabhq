class AddGroupIdToBoards < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :boards, :group_id, :integer
  end
end
