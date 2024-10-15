# frozen_string_literal: true

# rubocop:disable Migration/PreventIndexCreation -- inverse index yields better performance
class AddInverseIndexOnSbomOccurrencesTraversalIdsComponentName < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  OLD_INDEX = "index_sbom_occurrences_on_component_name_and_traversal_ids"
  NEW_INDEX = "index_sbom_occurrences_on_traversal_ids_and_component_name"
  TABLE = "sbom_occurrences"

  def up
    add_concurrent_index(
      TABLE,
      'traversal_ids, component_name COLLATE "C"',
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
      'component_name COLLATE "C", traversal_ids',
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
