class AddPasswordExpiresAtToUsers < ActiveRecord::Migration
  def change
    add_column :users, :password_expires_at, :datetime
  end
end
