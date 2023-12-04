# frozen_string_literal: true

class DropApplicationSettingsProductAnalyticsClusterSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string, if_exists: true
    remove_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string_iv, if_exists: true
    remove_column :application_settings, :encrypted_jitsu_administrator_password, if_exists: true
    remove_column :application_settings, :encrypted_jitsu_administrator_password_iv, if_exists: true
    remove_column :application_settings, :jitsu_host, if_exists: true
    remove_column :application_settings, :jitsu_project_xid, if_exists: true
    remove_column :application_settings, :jitsu_administrator_email, if_exists: true
  end

  def down
    add_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string,
      :binary, if_not_exists: true
    add_column :application_settings, :encrypted_product_analytics_clickhouse_connection_string_iv,
      :binary, if_not_exists: true
    add_column :application_settings, :encrypted_jitsu_administrator_password,
      :binary, if_not_exists: true
    add_column :application_settings, :encrypted_jitsu_administrator_password_iv,
      :binary, if_not_exists: true

    add_column :application_settings, :jitsu_host, :text, if_not_exists: true
    add_column :application_settings, :jitsu_project_xid, :text, if_not_exists: true
    add_column :application_settings, :jitsu_administrator_email, :text, if_not_exists: true

    add_text_limit :application_settings, :jitsu_host, 255
    add_text_limit :application_settings, :jitsu_project_xid, 255
    add_text_limit :application_settings, :jitsu_administrator_email, 255
  end
end
