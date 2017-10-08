# rubocop:disable all
class AddIndexToUsersAuthenticationToken < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :authentication_token, unique: true
  end
end
