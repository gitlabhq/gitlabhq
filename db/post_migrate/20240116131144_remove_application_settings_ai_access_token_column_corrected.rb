# frozen_string_literal: true

class RemoveApplicationSettingsAiAccessTokenColumnCorrected < Gitlab::Database::Migration[2.2]
  milestone '16.9'

  def up
    remove_column :application_settings, :encrypted_ai_access_token, if_exists: true
    remove_column :application_settings, :encrypted_ai_access_token_iv, if_exists: true
  end

  def down
    add_column :application_settings, :encrypted_ai_access_token, :binary, if_not_exists: true
    add_column :application_settings, :encrypted_ai_access_token_iv, :binary, if_not_exists: true
  end
end
