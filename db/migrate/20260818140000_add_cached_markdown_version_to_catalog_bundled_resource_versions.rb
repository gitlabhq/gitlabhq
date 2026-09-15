# frozen_string_literal: true

class AddCachedMarkdownVersionToCatalogBundledResourceVersions < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    add_column :catalog_bundled_resource_versions, :cached_markdown_version, :integer
  end
end
