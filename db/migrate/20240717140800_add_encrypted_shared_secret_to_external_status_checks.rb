# frozen_string_literal: true

class AddEncryptedSharedSecretToExternalStatusChecks < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '17.3'

  def change
    add_column :external_status_checks, :encrypted_shared_secret, :binary
    add_column :external_status_checks, :encrypted_shared_secret_iv, :binary
  end
end
