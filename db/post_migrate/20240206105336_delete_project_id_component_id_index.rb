# frozen_string_literal: true

class DeleteProjectIdComponentIdIndex < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.9'
  INDEX_NAME = 'index_sbom_occurrences_on_project_id_component_id'

  def up
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end

  def down
    add_concurrent_index :sbom_occurrences, [:project_id, :component_id], name: INDEX_NAME
  end
end
