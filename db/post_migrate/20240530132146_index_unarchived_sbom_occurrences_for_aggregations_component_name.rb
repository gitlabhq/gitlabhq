# frozen_string_literal: true

class IndexUnarchivedSbomOccurrencesForAggregationsComponentName < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unarchived_occurrences_for_aggregations_component_name'
  COLUMNS = [:traversal_ids, :component_name, :component_id, :component_version_id]

  milestone '17.1'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index :sbom_occurrences, COLUMNS, where: 'archived = false', name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
