class AddDeviseTwoFactorBackupableToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_backup_codes, :text
  end
end
