# frozen_string_literal: true

class AddDuoFeaturesEnabledToProjectSettings < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.9'

  def change
    add_column :project_settings, :duo_features_enabled, :boolean, default: true, null: false
  end
end
