class AddHideNoSshKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :hide_no_ssh_key, :boolean, :default => false
  end
end
