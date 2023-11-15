# frozen_string_literal: true

class AddEnforceSshCertificatesToNamespaceSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.7'

  def change
    add_column :namespace_settings, :enforce_ssh_certificates, :boolean, default: false, null: false
  end
end
