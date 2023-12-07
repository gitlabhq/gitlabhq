# frozen_string_literal: true

class AddIndexDependencyProxyPackageSettingsEnabledForMaven < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  INDEX_NAME = 'idx_dep_proxy_pkgs_settings_enabled_maven_on_project_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index(
      :dependency_proxy_packages_settings,
      :project_id,
      name: INDEX_NAME,
      where: 'enabled = TRUE AND maven_external_registry_url IS NOT NULL'
    )
  end

  def down
    remove_concurrent_index_by_name(:dependency_proxy_packages_settings, name: INDEX_NAME)
  end
end
