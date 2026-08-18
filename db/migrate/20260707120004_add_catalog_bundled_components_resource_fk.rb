# frozen_string_literal: true

class AddCatalogBundledComponentsResourceFk < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :catalog_bundled_resource_components, :catalog_bundled_resources,
      column: :catalog_bundled_resource_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :catalog_bundled_resource_components, :catalog_bundled_resources,
      column: :catalog_bundled_resource_id
  end
end
