# frozen_string_literal: true

class RenameOldIndexToNewIndexInCatalogResources < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  enable_lock_retries!

  OLD_INDEX_NAME = 'index_catalog_resources_on_search_vector_triagram'
  NEW_INDEX_NAME = 'index_catalog_resources_on_search_vector'

  def change
    rename_index :catalog_resources, OLD_INDEX_NAME, NEW_INDEX_NAME
  end
end
