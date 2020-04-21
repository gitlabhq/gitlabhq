class AddExternalAuthMutualTlsFieldsToProjectSettings < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    add_column :application_settings,
               :external_auth_client_cert, :text
    add_column :application_settings,
               :encrypted_external_auth_client_key, :text
    add_column :application_settings,
               :encrypted_external_auth_client_key_iv, :string
    add_column :application_settings,
               :encrypted_external_auth_client_key_pass, :string
    add_column :application_settings,
               :encrypted_external_auth_client_key_pass_iv, :string
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/PreventStrings
end
