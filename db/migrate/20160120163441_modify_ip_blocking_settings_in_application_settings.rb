class ModifyIpBlockingSettingsInApplicationSettings < ActiveRecord::Migration
  def change
    remove_column :application_settings, :dnsbl_servers_list

    add_column :application_settings, :dns_blacklist_threshold, :float, default: 0.33
    add_column :application_settings, :dns_whitelist_threshold, :float, default: 0.33
  end
end
