class AddAdminNotificationEmailSetting < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :admin_notification_email, :string
  end
end
