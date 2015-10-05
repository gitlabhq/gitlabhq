class AddLayoutOptionForUsers < ActiveRecord::Migration
  def change
    add_column :users, :layout, :integer, default: 0
  end
end