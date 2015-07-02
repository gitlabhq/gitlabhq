class AddDefaultOtpRequiredForLoginValue < ActiveRecord::Migration
  def up
    execute %q{UPDATE users SET otp_required_for_login = FALSE WHERE otp_required_for_login IS NULL}

    change_column :users, :otp_required_for_login, :boolean, default: false, null: false
  end

  def down
    change_column :users, :otp_required_for_login, :boolean, null: true
  end
end
