# frozen_string_literal: true

class AddIndexProjectIdComponentVersionIdIdOnSbomOccurrences < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'index_sbom_occurr_on_project_id_and_component_version_id_and_id'

  disable_ddl_transaction!
  milestone '16.8'

  def up
    add_concurrent_index :sbom_occurrences, [:project_id, :component_version_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrence, INDEX_NAME
  end
end
