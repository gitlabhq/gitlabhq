# frozen_string_literal: true

class DropReadmeColumnsFromCatalogBundledResourceVersions < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  TABLE_NAME = :catalog_bundled_resource_versions

  def up
    remove_column TABLE_NAME, :readme, if_exists: true
    remove_column TABLE_NAME, :readme_html, if_exists: true
  end

  def down
    add_column TABLE_NAME, :readme, :text, if_not_exists: true
    add_column TABLE_NAME, :readme_html, :text, if_not_exists: true
  end
end
