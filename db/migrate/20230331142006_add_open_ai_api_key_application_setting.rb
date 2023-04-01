# frozen_string_literal: true

class AddOpenAiApiKeyApplicationSetting < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :encrypted_openai_api_key, :binary
    add_column :application_settings, :encrypted_openai_api_key_iv, :binary
  end
end
