# frozen_string_literal: true

class IndexSbomOccurrencesForAggregations < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_unarchived_sbom_occurrences_for_aggregations'

  milestone '17.0'

  disable_ddl_transaction!

  # rubocop:disable Migration/PreventIndexCreation -- Legacy migration
  def up
    add_concurrent_index :sbom_occurrences, [:traversal_ids, :component_id, :component_version_id],
      where: 'archived = false',
      name: INDEX_NAME
  end
  # rubocop:enable Migration/PreventIndexCreation

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
