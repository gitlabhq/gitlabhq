# frozen_string_literal: true

class AddArkoseLabsDataExchangeKeyToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :application_settings, :encrypted_arkose_labs_data_exchange_key, :binary
    add_column :application_settings, :encrypted_arkose_labs_data_exchange_key_iv, :binary
  end
end
