# frozen_string_literal: true

class AddDuoNanoFeaturesEnabledToNamespaceSettings < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column :namespace_settings, :duo_nano_features_enabled, :boolean, null: true
  end
end
