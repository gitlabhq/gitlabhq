# frozen_string_literal: true

class AddMailgunSettingsToApplicationSetting < ActiveRecord::Migration[6.1]
  def change
    add_column :application_settings, :encrypted_mailgun_signing_key, :binary
    add_column :application_settings, :encrypted_mailgun_signing_key_iv, :binary

    add_column :application_settings, :mailgun_events_enabled, :boolean, default: false, null: false
  end
end
