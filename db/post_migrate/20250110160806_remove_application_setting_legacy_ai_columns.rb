# frozen_string_literal: true

class RemoveApplicationSettingLegacyAiColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  def up
    with_lock_retries do
      remove_column(:application_settings, :encrypted_openai_api_key, if_exists: true)
      remove_column(:application_settings, :encrypted_openai_api_key_iv, if_exists: true)
      remove_column(:application_settings, :encrypted_anthropic_api_key, if_exists: true)
      remove_column(:application_settings, :encrypted_anthropic_api_key_iv, if_exists: true)
      remove_column(:application_settings, :encrypted_vertex_ai_credentials, if_exists: true)
      remove_column(:application_settings, :encrypted_vertex_ai_credentials_iv, if_exists: true)
      remove_column(:application_settings, :encrypted_vertex_ai_access_token, if_exists: true)
      remove_column(:application_settings, :encrypted_vertex_ai_access_token_iv, if_exists: true)
    end
  end

  def down
    with_lock_retries do
      add_column(:application_settings, :encrypted_openai_api_key, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_openai_api_key_iv, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_anthropic_api_key, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_anthropic_api_key_iv, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_vertex_ai_credentials, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_vertex_ai_credentials_iv, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_vertex_ai_access_token, :binary, if_not_exists: true)
      add_column(:application_settings, :encrypted_vertex_ai_access_token_iv, :binary, if_not_exists: true)
    end
  end
end
