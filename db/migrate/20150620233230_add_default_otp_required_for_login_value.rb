class AddDefaultOtpRequiredForLoginValue < ActiveRecord::Migration
  def up
    change_column :users, :otp_required_for_login, :boolean, default: false, null: false
  end

  def down
    change_column :users, :otp_required_for_login, :boolean, default: nil
  end
end
