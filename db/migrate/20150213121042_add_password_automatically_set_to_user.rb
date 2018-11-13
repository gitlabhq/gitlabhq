# rubocop:disable all
class AddPasswordAutomaticallySetToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :password_automatically_set, :boolean, default: false
  end
end
