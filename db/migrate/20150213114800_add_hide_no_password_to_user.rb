# rubocop:disable all
class AddHideNoPasswordToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :hide_no_password, :boolean, default: false
  end
end
