# frozen_string_literal: true

class RemoveNameDescriptionTrigramIndexesFromCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  NAME_TRIGRAM_INDEX = 'index_catalog_resources_on_name_trigram'
  DESCRIPTION_TRIGRAM_INDEX = 'index_catalog_resources_on_description_trigram'

  def up
    remove_concurrent_index_by_name :catalog_resources, NAME_TRIGRAM_INDEX
    remove_concurrent_index_by_name :catalog_resources, DESCRIPTION_TRIGRAM_INDEX
  end

  def down
    add_concurrent_index :catalog_resources, :name, name: NAME_TRIGRAM_INDEX,
      using: :gin, opclass: { name: :gin_trgm_ops }

    add_concurrent_index :catalog_resources, :description, name: DESCRIPTION_TRIGRAM_INDEX,
      using: :gin, opclass: { description: :gin_trgm_ops }
  end
end
