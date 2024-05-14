# frozen_string_literal: true

class AddServicePingSettingsJsonColumnToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  disable_ddl_transaction!

  def up
    add_column :application_settings, :service_ping_settings, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(service_ping_settings) = 'object')",
      'check_application_settings_service_ping_settings_is_hash'
    )
  end

  def down
    remove_column :application_settings, :service_ping_settings
  end
end
