# frozen_string_literal: true

class AddEncryptedAiAccessToken < Gitlab::Database::Migration[2.1]
  def change
    add_column :application_settings, :encrypted_ai_access_token, :binary
    add_column :application_settings, :encrypted_ai_access_token_iv, :binary
  end
end
