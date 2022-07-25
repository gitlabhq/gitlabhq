# frozen_string_literal: true

class RemovePatAndSshEnforcementColumnsFromApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    remove_column :application_settings, :enforce_pat_expiration, :boolean, default: true, null: false
    remove_column :application_settings, :enforce_ssh_key_expiration, :boolean, default: true, null: false
  end
end
