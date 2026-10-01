# frozen_string_literal: true

class AddPinnedVersionFkToAiCatalogItemVersionDependencies < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  FK_NAME = 'fk_ai_catalog_dependency_pinned_version'

  def up
    # Guarantees dependency_version_id, when set, points at a version of the
    # dependency item. Unenforced while dependency_version_id is NULL.
    # No ON DELETE action: deleting a pinned version is an error while a
    # dependency row references it. Deletion paths clean up the rows first.
    add_concurrent_foreign_key :ai_catalog_item_version_dependencies, :ai_catalog_item_versions,
      column: [:dependency_id, :dependency_version_id],
      target_column: [:ai_catalog_item_id, :id],
      on_delete: nil,
      name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :ai_catalog_item_version_dependencies, :ai_catalog_item_versions,
        column: [:dependency_id, :dependency_version_id], name: FK_NAME
    end
  end
end
