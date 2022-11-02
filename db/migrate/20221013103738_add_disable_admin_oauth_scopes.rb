# frozen_string_literal: true

class AddDisableAdminOauthScopes < Gitlab::Database::Migration[2.0]
  def change
    add_column :application_settings, :disable_admin_oauth_scopes, :boolean, null: false, default: false
  end
end
