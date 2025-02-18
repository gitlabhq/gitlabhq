# frozen_string_literal: true

class AddAntiAbuseSettingsToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    add_column :application_settings, :anti_abuse_settings, :jsonb, default: {}, null: false

    add_check_constraint(
      :application_settings,
      "(jsonb_typeof(anti_abuse_settings) = 'object')",
      'check_anti_abuse_settings_is_hash'
    )
  end

  def down
    remove_column :application_settings, :anti_abuse_settings
  end
end
