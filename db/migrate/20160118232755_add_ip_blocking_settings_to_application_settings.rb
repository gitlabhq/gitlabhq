class AddIpBlockingSettingsToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :ip_blocking_enabled, :boolean, default: false
    add_column :application_settings, :dnsbl_servers_list, :text
  end
end
