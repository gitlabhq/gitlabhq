# frozen_string_literal: true

class AddIndexOnAiCatalogItemVersionDependenciesForDependencyVersionAndOrg < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  COLUMNS = %i[ai_catalog_item_version_id dependency_id organization_id]
  INDEX_NAME = 'idx_ai_catalog_item_version_dependencies_version_and_dependency'

  def up
    add_concurrent_index :ai_catalog_item_version_dependencies, COLUMNS, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ai_catalog_item_version_dependencies, INDEX_NAME
  end
end
