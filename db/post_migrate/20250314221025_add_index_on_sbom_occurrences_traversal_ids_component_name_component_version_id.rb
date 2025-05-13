# frozen_string_literal: true

# rubocop:disable Migration/PreventIndexCreation -- Using a composite index that can serve multiple query patterns
class AddIndexOnSbomOccurrencesTraversalIdsComponentNameComponentVersionId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '18.0'

  OLD_INDEX = "index_sbom_occurrences_on_traversal_ids_and_component_name"
  NEW_INDEX = "idx_sbom_occurr_on_traversal_ids_and_comp_name_and_comp_ver_id"
  TABLE = "sbom_occurrences"

  def up
    add_concurrent_index(
      TABLE,
      'traversal_ids, component_name COLLATE "C", component_version_id',
      using: 'btree',
      name: NEW_INDEX
    )
    remove_concurrent_index_by_name(
      TABLE,
      OLD_INDEX
    )
  end

  def down
    add_concurrent_index(
      TABLE,
      'traversal_ids, component_name COLLATE "C"',
      using: 'btree',
      name: OLD_INDEX
    )
    remove_concurrent_index_by_name(
      TABLE,
      NEW_INDEX
    )
  end
end
# rubocop:enable Migration/PreventIndexCreation
