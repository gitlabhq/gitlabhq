# frozen_string_literal: true

class AddSyncIndexToSbomOccurrencesForSeverityAggregations < Gitlab::Database::Migration[2.2]
  TABLE_NAME = :sbom_occurrences
  COLUMNS = %i[traversal_ids highest_severity component_id component_version_id]
  INDEX = 'idx_unarchived_occurrences_for_aggregation_severity_nulls_first'

  disable_ddl_transaction!
  milestone '17.7'

  def up
    add_concurrent_index(
      TABLE_NAME,
      COLUMNS,
      name: INDEX,
      where: 'archived = false',
      order: { highest_severity: 'NULLS FIRST' }
    )
  end

  def down
    remove_concurrent_index(
      TABLE_NAME,
      COLUMNS,
      name: INDEX,
      where: 'archived = false',
      order: { highest_severity: 'NULLS FIRST' }
    )
  end
end
