class AddAdminNotificationEmailSetting < ActiveRecord::Migration
  def change
    add_column :application_settings, :admin_notification_email, :string
  end
end
