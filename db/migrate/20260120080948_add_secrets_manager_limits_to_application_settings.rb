# frozen_string_literal: true

class AddSecretsManagerLimitsToApplicationSettings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  def change
    add_column :application_settings, :secrets_manager_settings, :jsonb, default: {}, null: false
  end
end
