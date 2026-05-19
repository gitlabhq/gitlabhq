# frozen_string_literal: true

class AddPersonalAccessTokenSettingsToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  def change
    add_column :namespace_settings, :personal_access_token_settings, :jsonb, default: {}, null: false
  end
end
