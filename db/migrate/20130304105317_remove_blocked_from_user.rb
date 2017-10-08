# rubocop:disable all
class RemoveBlockedFromUser < ActiveRecord::Migration[4.2]
  def up
    remove_column :users, :blocked
  end

  def down
    add_column :users, :blocked, :boolean
  end
end
