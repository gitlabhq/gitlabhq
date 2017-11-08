class AddWeightToBoards < ActiveRecord::Migration
  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_column :boards, :weight, :integer, index: true
  end
end
