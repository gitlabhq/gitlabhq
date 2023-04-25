# frozen_string_literal: true

class AddPackageRegistryAccessLevelIntoProjectFeatures < Gitlab::Database::Migration[1.0]
  DISABLED = 0 # ProjectFeature::DISABLED

  def up
    add_column :project_features, :package_registry_access_level, :integer, default: DISABLED, null: false
  end

  def down
    remove_column :project_features, :package_registry_access_level
  end
end
