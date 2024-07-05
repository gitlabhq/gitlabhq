# frozen_string_literal: true

class IndexSbomOccurrencesOnTraversalIdsAndId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.2'

  INDEX_NAME = 'index_sbom_occurrences_on_traversal_ids_and_id'

  def up
    add_concurrent_index :sbom_occurrences, %i[traversal_ids id], name: INDEX_NAME, where: 'archived = FALSE' # rubocop:disable Migration/PreventIndexCreation -- This index is required for export feature
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
