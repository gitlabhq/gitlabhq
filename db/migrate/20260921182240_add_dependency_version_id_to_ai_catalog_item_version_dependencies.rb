# frozen_string_literal: true

class AddDependencyVersionIdToAiCatalogItemVersionDependencies < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_ai_catalog_dependencies_on_dep_version_id_and_dep_id'

  def up
    with_lock_retries do
      add_column :ai_catalog_item_version_dependencies, :dependency_version_id, :bigint, null: true,
        if_not_exists: true
    end

    add_concurrent_index :ai_catalog_item_version_dependencies, [:dependency_version_id, :dependency_id],
      name: INDEX_NAME
  end

  def down
    remove_column :ai_catalog_item_version_dependencies, :dependency_version_id, :bigint
  end
end
