# rubocop:disable all
class AddAvatarToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :avatar, :string
  end
end
