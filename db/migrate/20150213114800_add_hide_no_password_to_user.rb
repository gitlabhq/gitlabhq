class AddHideNoPasswordToUser < ActiveRecord::Migration
  def change
    add_column :users, :hide_no_password, :boolean, default: false
  end
end
