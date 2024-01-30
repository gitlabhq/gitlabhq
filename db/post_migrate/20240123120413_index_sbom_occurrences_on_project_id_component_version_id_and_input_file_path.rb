# frozen_string_literal: true

class IndexSbomOccurrencesOnProjectIdComponentVersionIdAndInputFilePath < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_sbom_occurr_on_project_component_version_input_file_path'
  DROPPED_INDEX_NAME = 'index_sbom_occurrences_for_input_file_path_search'
  disable_ddl_transaction!
  milestone '16.9'

  def up
    remove_concurrent_index_by_name :sbom_occurrences, DROPPED_INDEX_NAME
    add_concurrent_index :sbom_occurrences, %i[project_id component_version_id input_file_path], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
    add_concurrent_index :sbom_occurrences, %i[project_id component_id input_file_path], name: DROPPED_INDEX_NAME
  end
end
