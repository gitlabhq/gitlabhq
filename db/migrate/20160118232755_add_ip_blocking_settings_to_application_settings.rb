class AddIpBlockingSettingsToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :ip_blocking_enabled, :boolean, default: false
    add_column :application_settings, :dns_blacklist_threshold, :float, default: 0.33
    add_column :application_settings, :dns_whitelist_threshold, :float, default: 0.33
  end
end
