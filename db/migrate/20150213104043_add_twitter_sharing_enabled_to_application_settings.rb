# rubocop:disable all
class AddTwitterSharingEnabledToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :twitter_sharing_enabled, :boolean, default: true
  end
end
