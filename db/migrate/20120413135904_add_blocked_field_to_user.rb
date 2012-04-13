class AddBlockedFieldToUser < ActiveRecord::Migration
  def change
    add_column :users, :blocked, :boolean, :null => false, :default => false
  end
end
