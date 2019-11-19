# frozen_string_literal: true

class AddEksCredentialsToApplicationSettings < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :application_settings, :eks_integration_enabled, :boolean, null: false, default: false
    add_column :application_settings, :eks_account_id, :string, limit: 128
    add_column :application_settings, :eks_access_key_id, :string, limit: 128
    add_column :application_settings, :encrypted_eks_secret_access_key_iv, :string, limit: 255
    add_column :application_settings, :encrypted_eks_secret_access_key, :text
  end
end
