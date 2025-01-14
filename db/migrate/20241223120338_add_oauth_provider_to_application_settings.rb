# frozen_string_literal: true

class AddOauthProviderToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '17.8'

  def change
    add_column :application_settings, :oauth_provider, :jsonb, if_not_exists: true, null: false, default: {}
  end
end
