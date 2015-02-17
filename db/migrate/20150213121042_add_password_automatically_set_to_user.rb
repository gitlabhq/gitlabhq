class AddPasswordAutomaticallySetToUser < ActiveRecord::Migration
  def change
    add_column :users, :password_automatically_set, :boolean, default: false
  end
end
