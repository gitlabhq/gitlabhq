# frozen_string_literal: true

class AddIndexForComponentNamesSearch < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  INDEX_NAME = 'index_sbom_occurrences_on_name_traversal_ids_and_component'

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Replacing another index removed in migration 20250925200929
    add_concurrent_index :sbom_occurrences, 'component_name COLLATE "C", traversal_ids, component_id', name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
