class RemoveBlockedFromUser < ActiveRecord::Migration
  def up
    remove_column :users, :blocked
  end

  def down
    add_column :users, :blocked, :boolean
  end
end
