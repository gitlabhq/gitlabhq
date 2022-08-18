# frozen_string_literal: true

class AddIndexToSbomOccurrencesComponentId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = "index_sbom_occurrences_on_component_id"

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, :component_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, name: INDEX_NAME
  end
end
