# frozen_string_literal: true

class AddIndexOnSbomOccurrencesHighestSeverity < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.7'

  INDEX_NAME = 'index_sbom_occurrences_on_highest_severity'
  INDEX_TO_BE_REMOVED = 'index_sbom_occurrences_on_project_id'

  def up
    add_concurrent_index :sbom_occurrences,
      [:project_id, :highest_severity],
      order: { highest_severity: 'DESC NULLS LAST' },
      name: INDEX_NAME

    remove_concurrent_index_by_name :sbom_occurrences, INDEX_TO_BE_REMOVED
  end

  def down
    add_concurrent_index :sbom_occurrences, :project_id, name: INDEX_TO_BE_REMOVED
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
