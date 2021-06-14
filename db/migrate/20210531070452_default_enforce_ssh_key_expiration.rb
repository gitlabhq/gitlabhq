# frozen_string_literal: true

class DefaultEnforceSshKeyExpiration < ActiveRecord::Migration[6.0]
  def change
    change_column_default(:application_settings, :enforce_ssh_key_expiration, from: false, to: true)
  end
end
