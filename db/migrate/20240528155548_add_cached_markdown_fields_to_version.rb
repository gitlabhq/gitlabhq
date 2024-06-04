# frozen_string_literal: true

class AddCachedMarkdownFieldsToVersion < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    add_column :catalog_resource_versions, :cached_markdown_version, :integer, null: true
    # rubocop:disable Migration/AddLimitToTextColumns -- It will be limited by description
    add_column :catalog_resource_versions, :readme, :text, null: true
    add_column :catalog_resource_versions, :readme_html, :text, null: true
    # rubocop:enable Migration/AddLimitToTextColumns -- It will be limited by description
  end

  def down
    remove_column :catalog_resource_versions, :cached_markdown_version, :integer, null: true
    remove_column :catalog_resource_versions, :readme, :text, null: true
    remove_column :catalog_resource_versions, :readme_html, :text, null: true
  end
end
