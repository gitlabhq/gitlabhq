class RemoveIpBlockingSettingsFromApplicationSettings < ActiveRecord::Migration
  def change
    remove_column :application_settings, :ip_blocking_enabled, :boolean, default: false
    remove_column :application_settings, :dnsbl_servers_list, :text
  end
end
