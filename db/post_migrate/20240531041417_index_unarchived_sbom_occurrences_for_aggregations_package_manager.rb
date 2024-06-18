# frozen_string_literal: true

class IndexUnarchivedSbomOccurrencesForAggregationsPackageManager < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unarchived_occurrences_for_aggregations_package_manager'
  COLUMNS = [:traversal_ids, :package_manager, :component_id, :component_version_id]

  milestone '17.1'

  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/PreventIndexCreation -- Discussed in cop MR
    add_concurrent_index :sbom_occurrences, COLUMNS, where: 'archived = false', name: INDEX_NAME
    # rubocop:enable Migration/PreventIndexCreation
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
