# frozen_string_literal: true

class AddEnforceSshKeyExpirationToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :enforce_ssh_key_expiration, :boolean, default: false, null: false
  end
end
