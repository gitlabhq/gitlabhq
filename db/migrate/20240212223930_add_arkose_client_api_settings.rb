# frozen_string_literal: true

class AddArkoseClientApiSettings < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  enable_lock_retries!

  def up
    add_column :application_settings, :encrypted_arkose_labs_client_xid, :binary
    add_column :application_settings, :encrypted_arkose_labs_client_xid_iv, :binary

    add_column :application_settings, :encrypted_arkose_labs_client_secret, :binary
    add_column :application_settings, :encrypted_arkose_labs_client_secret_iv, :binary
  end

  def down
    remove_column :application_settings, :encrypted_arkose_labs_client_xid, :binary
    remove_column :application_settings, :encrypted_arkose_labs_client_xid_iv, :binary

    remove_column :application_settings, :encrypted_arkose_labs_client_secret, :binary
    remove_column :application_settings, :encrypted_arkose_labs_client_secret_iv, :binary
  end
end
