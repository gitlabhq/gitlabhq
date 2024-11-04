# frozen_string_literal: true

class AddIndexOnSbomOccurrencesTraversalIdsPackageManager < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.6'

  INDEX_NAME = "index_sbom_occurrences_on_traversal_ids_and_package_manager"
  TABLE = "sbom_occurrences"

  # rubocop:disable Migration/PreventIndexCreation -- needed to feature development
  def up
    add_concurrent_index(
      TABLE,
      'traversal_ids, package_manager COLLATE "C"',
      using: 'btree',
      name: INDEX_NAME
    )
  end

  def down
    remove_concurrent_index_by_name(
      TABLE,
      INDEX_NAME
    )
  end
  # rubocop:enable Migration/PreventIndexCreation -- needed to feature development
end
