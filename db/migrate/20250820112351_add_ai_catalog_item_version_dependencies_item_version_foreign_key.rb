# frozen_string_literal: true

class AddAiCatalogItemVersionDependenciesItemVersionForeignKey < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :ai_catalog_item_version_dependencies,
      :ai_catalog_item_versions,
      column: :ai_catalog_item_version_id, on_delete: :cascade
    )
  end

  def down
    with_lock_retries do
      remove_foreign_key :ai_catalog_item_version_dependencies, column: :ai_catalog_item_version_id
    end
  end
end
