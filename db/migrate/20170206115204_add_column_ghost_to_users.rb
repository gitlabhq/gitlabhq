class AddColumnGhostToUsers < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    add_column :users, :ghost, :boolean
  end

  def down
    remove_column :users, :ghost
  end
end
