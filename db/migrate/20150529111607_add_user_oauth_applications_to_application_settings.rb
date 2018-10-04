class AddUserOauthApplicationsToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :user_oauth_applications, :bool, default: true
  end
end
