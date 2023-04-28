# frozen_string_literal: true

class AddProductAnalyticsToProjectSettings < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :project_settings, :jitsu_host, :text, if_not_exists: true
      add_column :project_settings, :jitsu_project_xid, :text, if_not_exists: true
      add_column :project_settings, :jitsu_administrator_email, :text, if_not_exists: true
      add_column :project_settings, :encrypted_jitsu_administrator_password, :binary, if_not_exists: true
      add_column :project_settings, :encrypted_jitsu_administrator_password_iv, :binary, if_not_exists: true
      add_column :project_settings, :product_analytics_data_collector_host, :text, if_not_exists: true
      add_column :project_settings, :encrypted_product_analytics_clickhouse_connection_string,
        :binary, if_not_exists: true
      add_column :project_settings, :encrypted_product_analytics_clickhouse_connection_string_iv,
        :binary, if_not_exists: true
      add_column :project_settings, :cube_api_base_url, :text, if_not_exists: true
      add_column :project_settings, :encrypted_cube_api_key, :binary, if_not_exists: true
      add_column :project_settings, :encrypted_cube_api_key_iv, :binary, if_not_exists: true
    end

    add_text_limit :project_settings, :jitsu_host, 255
    add_text_limit :project_settings, :jitsu_project_xid, 255
    add_text_limit :project_settings, :jitsu_administrator_email, 255
    add_text_limit :project_settings, :product_analytics_data_collector_host, 255
    add_text_limit :project_settings, :cube_api_base_url, 512
  end

  def down
    with_lock_retries do
      remove_column :project_settings, :jitsu_host, if_exists: true
      remove_column :project_settings, :jitsu_project_xid, if_exists: true
      remove_column :project_settings, :jitsu_administrator_email, if_exists: true
      remove_column :project_settings, :encrypted_jitsu_administrator_password, if_exists: true
      remove_column :project_settings, :encrypted_jitsu_administrator_password_iv, if_exists: true
      remove_column :project_settings, :product_analytics_data_collector_host, if_exists: true
      remove_column :project_settings, :encrypted_product_analytics_clickhouse_connection_string, if_exists: true
      remove_column :project_settings, :encrypted_product_analytics_clickhouse_connection_string_iv, if_exists: true
      remove_column :project_settings, :cube_api_base_url, if_exists: true
      remove_column :project_settings, :encrypted_cube_api_key, if_exists: true
      remove_column :project_settings, :encrypted_cube_api_key_iv, if_exists: true
    end
  end
end
