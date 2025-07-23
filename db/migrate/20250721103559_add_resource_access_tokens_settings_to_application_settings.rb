# frozen_string_literal: true

class AddResourceAccessTokensSettingsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :application_settings, :resource_access_tokens_settings, :jsonb, default: {}, null: false
  end
end
