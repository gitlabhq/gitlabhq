# frozen_string_literal: true

class IndexProjectIdComponentIdAndIdForSbomOccurrences < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_sbom_occurrences_on_project_id_and_component_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, [:project_id, :component_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
