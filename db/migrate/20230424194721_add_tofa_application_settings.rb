# frozen_string_literal: true

class AddTofaApplicationSettings < Gitlab::Database::Migration[2.1]
  def change
    change_table(:application_settings, bulk: true) do |t|
      t.column :encrypted_tofa_credentials, :binary
      t.column :encrypted_tofa_credentials_iv, :binary
      t.column :encrypted_tofa_host, :binary
      t.column :encrypted_tofa_host_iv, :binary
      t.column :encrypted_tofa_url, :binary
      t.column :encrypted_tofa_url_iv, :binary
      t.column :encrypted_tofa_response_json_keys, :binary
      t.column :encrypted_tofa_response_json_keys_iv, :binary
      t.column :encrypted_tofa_request_json_keys, :binary
      t.column :encrypted_tofa_request_json_keys_iv, :binary
      t.column :encrypted_tofa_request_payload, :binary
      t.column :encrypted_tofa_request_payload_iv, :binary
      t.column :encrypted_tofa_client_library_class, :binary
      t.column :encrypted_tofa_client_library_class_iv, :binary
      t.column :encrypted_tofa_client_library_args, :binary
      t.column :encrypted_tofa_client_library_args_iv, :binary
      t.column :encrypted_tofa_client_library_create_credentials_method, :binary
      t.column :encrypted_tofa_client_library_create_credentials_method_iv, :binary
      t.column :encrypted_tofa_client_library_fetch_access_token_method, :binary
      t.column :encrypted_tofa_client_library_fetch_access_token_method_iv, :binary
      t.column :encrypted_tofa_access_token_expires_in, :binary
      t.column :encrypted_tofa_access_token_expires_in_iv, :binary
    end
  end
end
