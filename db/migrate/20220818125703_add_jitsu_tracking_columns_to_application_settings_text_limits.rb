# frozen_string_literal: true

class AddJitsuTrackingColumnsToApplicationSettingsTextLimits < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :jitsu_host, 255
    add_text_limit :application_settings, :jitsu_project_xid, 255
    add_text_limit :application_settings, :clickhouse_connection_string, 1024
    add_text_limit :application_settings, :jitsu_administrator_email, 255
  end

  def down
    remove_text_limit :application_settings, :jitsu_host
    remove_text_limit :application_settings, :jitsu_project_xid
    remove_text_limit :application_settings, :clickhouse_connection_string
    remove_text_limit :application_settings, :jitsu_administrator_email
  end
end
