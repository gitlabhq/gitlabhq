# frozen_string_literal: true

class AddIndexSbomOccurrencesOnComponentNameAndTraversalId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  INDEX_NAME = "index_sbom_occurrences_on_component_name_and_traversal_ids"
  TABLE = "sbom_occurrences"

  def up
    # rubocop:disable Migration/PreventIndexCreation -- intended use is an index scan to enable filtering by component. Replaces a previously-added GIN index.
    add_concurrent_index(
      TABLE,
      'component_name COLLATE "C", traversal_ids',
      using: 'btree',
      name: INDEX_NAME
    )
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name(
      TABLE,
      INDEX_NAME
    )
  end
end
