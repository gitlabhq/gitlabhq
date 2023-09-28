# frozen_string_literal: true

class RemoveApplicationSettingsAiAccessTokenColumn < Gitlab::Database::Migration[2.1]
  def up
    remove_column :application_settings, :encrypted_ai_access_token
    remove_column :application_settings, :encrypted_ai_access_token_iv
  end

  def down
    add_column :application_settings, :encrypted_ai_access_token, :binary
    add_column :application_settings, :encrypted_ai_access_token_iv, :binary
  end
end
