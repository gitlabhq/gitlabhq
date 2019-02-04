class AddDeviseTwoFactorToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :otp_required_for_login, :boolean
  end
end
