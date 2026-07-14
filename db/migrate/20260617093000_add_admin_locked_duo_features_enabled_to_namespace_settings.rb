# frozen_string_literal: true

class AddAdminLockedDuoFeaturesEnabledToNamespaceSettings < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    add_column :namespace_settings, :admin_locked_duo_features_enabled, :boolean, default: false, null: false
  end
end
