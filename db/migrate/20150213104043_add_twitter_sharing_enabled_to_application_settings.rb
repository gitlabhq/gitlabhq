class AddTwitterSharingEnabledToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :twitter_sharing_enabled, :boolean, default: true
  end
end
