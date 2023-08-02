# frozen_string_literal: true

class RemoveApplicationSettingsIgnoredColumns < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    remove_column :application_settings, :encrypted_tofa_access_token_expires_in, if_exists: true
    remove_column :application_settings, :encrypted_tofa_access_token_expires_in_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_args, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_args_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_class, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_class_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_create_credentials_method, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_create_credentials_method_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_fetch_access_token_method, if_exists: true
    remove_column :application_settings, :encrypted_tofa_client_library_fetch_access_token_method_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_host, if_exists: true
    remove_column :application_settings, :encrypted_tofa_host_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_request_json_keys, if_exists: true
    remove_column :application_settings, :encrypted_tofa_request_json_keys_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_request_payload, if_exists: true
    remove_column :application_settings, :encrypted_tofa_request_payload_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_response_json_keys, if_exists: true
    remove_column :application_settings, :encrypted_tofa_response_json_keys_iv, if_exists: true
    remove_column :application_settings, :encrypted_tofa_url, if_exists: true
    remove_column :application_settings, :encrypted_tofa_url_iv, if_exists: true
  end

  def down
    add_column :application_settings, :encrypted_tofa_host, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_host_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_url, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_url_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_response_json_keys, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_response_json_keys_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_request_json_keys, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_request_json_keys_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_request_payload, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_request_payload_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_class, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_class_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_args, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_args_iv, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_create_credentials_method, :binary,
      if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_create_credentials_method_iv, :binary,
      if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_fetch_access_token_method, :binary,
      if_not_exists: true
    add_column :application_settings, :encrypted_tofa_client_library_fetch_access_token_method_iv, :binary,
      if_not_exists: true
    add_column :application_settings, :encrypted_tofa_access_token_expires_in, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_tofa_access_token_expires_in_iv, :binary, if_not_exists: true
  end
end
