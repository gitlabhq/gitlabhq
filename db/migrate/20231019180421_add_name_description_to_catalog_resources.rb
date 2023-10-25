# frozen_string_literal: true

class AddNameDescriptionToCatalogResources < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  NAME_INDEX = 'index_catalog_resources_on_name_trigram'
  DESCRIPTION_INDEX = 'index_catalog_resources_on_description_trigram'

  def up
    # These columns must match the settings for the corresponding columns in the `projects` table
    add_column :catalog_resources, :name, :varchar, null: true
    add_column :catalog_resources, :description, :text, null: true # rubocop: disable Migration/AddLimitToTextColumns

    add_concurrent_index :catalog_resources, :name, name: NAME_INDEX,
      using: :gin, opclass: { name: :gin_trgm_ops }

    add_concurrent_index :catalog_resources, :description, name: DESCRIPTION_INDEX,
      using: :gin, opclass: { description: :gin_trgm_ops }
  end

  def down
    remove_column :catalog_resources, :name
    remove_column :catalog_resources, :description

    remove_concurrent_index_by_name :catalog_resources, NAME_INDEX
    remove_concurrent_index_by_name :catalog_resources, DESCRIPTION_INDEX
  end
end
