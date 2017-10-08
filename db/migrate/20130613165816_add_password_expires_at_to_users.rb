# rubocop:disable all
class AddPasswordExpiresAtToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :password_expires_at, :datetime
  end
end
