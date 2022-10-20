# frozen_string_literal: true

class AddJitsuTrackingColumnsToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20220818125703_add_jitsu_tracking_columns_to_application_settings_text_limits.rb
    add_column :application_settings, :jitsu_host, :text
    add_column :application_settings, :jitsu_project_xid, :text
    add_column :application_settings, :clickhouse_connection_string, :text
    add_column :application_settings, :jitsu_administrator_email, :text
    add_column :application_settings, :encrypted_jitsu_administrator_password, :binary
    add_column :application_settings, :encrypted_jitsu_administrator_password_iv, :binary
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
