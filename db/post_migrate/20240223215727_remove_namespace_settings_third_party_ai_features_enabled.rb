# frozen_string_literal: true

class RemoveNamespaceSettingsThirdPartyAiFeaturesEnabled < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    remove_column :namespace_settings, :third_party_ai_features_enabled
  end

  def down
    add_column :namespace_settings, :third_party_ai_features_enabled, :boolean, default: true, null: false
  end
end
