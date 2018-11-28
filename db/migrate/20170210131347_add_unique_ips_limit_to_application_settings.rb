class AddUniqueIpsLimitToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  disable_ddl_transaction!

  def up
    add_column :application_settings, :unique_ips_limit_per_user, :integer
    add_column :application_settings, :unique_ips_limit_time_window, :integer
    add_column_with_default :application_settings, :unique_ips_limit_enabled, :boolean, default: false
  end

  def down
    remove_column :application_settings, :unique_ips_limit_per_user
    remove_column :application_settings, :unique_ips_limit_time_window
    remove_column :application_settings, :unique_ips_limit_enabled
  end
end
