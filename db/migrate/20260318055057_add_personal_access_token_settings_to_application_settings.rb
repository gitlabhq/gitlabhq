# frozen_string_literal: true

class AddPersonalAccessTokenSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  def change
    add_column :application_settings, :personal_access_token_settings, :jsonb, default: {}, null: false
  end
end
