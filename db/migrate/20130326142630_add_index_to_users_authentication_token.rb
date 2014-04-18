class AddIndexToUsersAuthenticationToken < ActiveRecord::Migration
  def change
    add_index :users, :authentication_token, unique: true
  end
end
