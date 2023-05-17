# frozen_string_literal: true

class IndexSbomOccurrencesOnProjectIdAndId < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'index_sbom_occurrences_on_project_id_and_id'

  def up
    add_concurrent_index :sbom_occurrences, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
