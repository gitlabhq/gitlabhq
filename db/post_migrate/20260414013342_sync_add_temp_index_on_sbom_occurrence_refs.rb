# frozen_string_literal: true

class SyncAddTempIndexOnSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'
  INDEX_NAME = 'tmp_idx_sbom_occurrence_refs_on_project_id_id'

  def up
    add_concurrent_index :sbom_occurrence_refs, [:project_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrence_refs, INDEX_NAME
  end
end
