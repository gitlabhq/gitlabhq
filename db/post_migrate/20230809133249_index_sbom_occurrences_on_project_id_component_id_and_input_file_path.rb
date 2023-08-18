# frozen_string_literal: true

class IndexSbomOccurrencesOnProjectIdComponentIdAndInputFilePath < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_sbom_occurrences_for_input_file_path_search'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, %i[project_id component_id input_file_path], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
