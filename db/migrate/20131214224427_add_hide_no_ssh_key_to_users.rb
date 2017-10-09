# rubocop:disable all
class AddHideNoSshKeyToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hide_no_ssh_key, :boolean, :default => false
  end
end
