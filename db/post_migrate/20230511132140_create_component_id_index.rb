# frozen_string_literal: true

class CreateComponentIdIndex < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_sbom_occurrences_on_project_id_component_id'

  def up
    return if index_exists_by_name?(:sbom_occurrences, INDEX_NAME)

    add_concurrent_index :sbom_occurrences, [:project_id, :component_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_sources, INDEX_NAME
  end
end
