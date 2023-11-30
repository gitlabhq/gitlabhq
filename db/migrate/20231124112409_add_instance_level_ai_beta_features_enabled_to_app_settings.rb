# frozen_string_literal: true

class AddInstanceLevelAiBetaFeaturesEnabledToAppSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  def change
    add_column :application_settings, :instance_level_ai_beta_features_enabled, :boolean, null: false, default: false
  end
end
