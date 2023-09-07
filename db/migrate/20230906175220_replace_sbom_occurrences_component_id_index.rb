# frozen_string_literal: true

class ReplaceSbomOccurrencesComponentIdIndex < Gitlab::Database::Migration[2.1]
  REMOVED_INDEX_NAME = "index_sbom_occurrences_on_component_id"
  ADDED_INDEX_NAME = "index_sbom_occurrences_on_component_id_and_id"

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, %i[component_id id], name: ADDED_INDEX_NAME
    remove_concurrent_index_by_name :sbom_occurrences, name: REMOVED_INDEX_NAME
  end

  def down
    add_concurrent_index :sbom_occurrences, :component_id, name: REMOVED_INDEX_NAME
    remove_concurrent_index_by_name :sbom_occurrences, name: ADDED_INDEX_NAME
  end
end
