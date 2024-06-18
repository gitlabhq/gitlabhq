# frozen_string_literal: true

class RemoveIndexOnSbomOccurrencesForAggregations < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_sbom_occurrences_for_aggregations'

  milestone '17.1'

  def up
    prepare_async_index_removal :sbom_occurrences, [:traversal_ids, :component_id, :component_version_id],
      name: INDEX_NAME
  end

  def down
    unprepare_async_index :sbom_occurrences, [:traversal_ids, :component_id, :component_version_id], name: INDEX_NAME
  end
end
