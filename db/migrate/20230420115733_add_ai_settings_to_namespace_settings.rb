# frozen_string_literal: true

class AddAiSettingsToNamespaceSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    add_column :namespace_settings, :experiment_features_enabled, :boolean, default: false, null: false
    add_column :namespace_settings, :third_party_ai_features_enabled, :boolean, default: true, null: false
  end
end
