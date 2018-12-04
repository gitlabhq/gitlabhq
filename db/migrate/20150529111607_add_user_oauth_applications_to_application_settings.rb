class AddUserOauthApplicationsToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :user_oauth_applications, :bool, default: true
  end
end
