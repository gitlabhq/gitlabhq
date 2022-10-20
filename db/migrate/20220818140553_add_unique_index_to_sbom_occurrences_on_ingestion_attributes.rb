# frozen_string_literal: true

class AddUniqueIndexToSbomOccurrencesOnIngestionAttributes < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_sbom_occurrences_on_ingestion_attributes'
  ATTRIBUTES = %i[
    project_id
    component_id
    component_version_id
    source_id
    commit_sha
  ].freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrences, ATTRIBUTES, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, name: INDEX_NAME
  end
end
