# frozen_string_literal: true

class AddAnthropicApiKeyApplicationSetting < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :encrypted_anthropic_api_key, :binary
    add_column :application_settings, :encrypted_anthropic_api_key_iv, :binary
  end
end
