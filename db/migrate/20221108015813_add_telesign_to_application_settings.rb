# frozen_string_literal: true

class AddTelesignToApplicationSettings < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :encrypted_telesign_customer_xid, :binary
    add_column :application_settings, :encrypted_telesign_customer_xid_iv, :binary

    add_column :application_settings, :encrypted_telesign_api_key, :binary
    add_column :application_settings, :encrypted_telesign_api_key_iv, :binary
  end
end
