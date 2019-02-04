class AddDeviseTwoFactorBackupableToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :otp_backup_codes, :text
  end
end
