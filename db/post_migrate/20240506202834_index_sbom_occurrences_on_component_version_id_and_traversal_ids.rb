# frozen_string_literal: true

class IndexSbomOccurrencesOnComponentVersionIdAndTraversalIds < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unarchived_occurrences_on_version_id_and_traversal_ids'

  milestone '17.0'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index :sbom_occurrences, [:component_version_id, :traversal_ids],
      where: 'archived = false',
      name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
