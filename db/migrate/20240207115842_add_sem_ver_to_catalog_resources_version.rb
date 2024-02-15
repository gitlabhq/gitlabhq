# frozen_string_literal: true

class AddSemVerToCatalogResourcesVersion < Gitlab::Database::Migration[2.2]
  enable_lock_retries!

  milestone '16.10'
  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in 20240213113719_add_text_limit_to_catalog_resource_versions_semver_prerelease

  def change
    add_column :catalog_resource_versions, :semver_major, :integer
    add_column :catalog_resource_versions, :semver_minor, :integer
    add_column :catalog_resource_versions, :semver_patch, :integer
    add_column :catalog_resource_versions, :semver_prerelease, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
