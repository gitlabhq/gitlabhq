# frozen_string_literal: true

class AddUniqueIndexOnSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.0'

  TABLE_NAME = :sbom_occurrence_refs
  INDEX_NAME = :idx_sbom_occurrence_refs_on_sbom_occ_id_and_tracked_context_id
  REDUNDANT_INDEX_NAME = :idx_sbom_occurrence_refs_on_occurrence_id

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[sbom_occurrence_id security_project_tracked_context_id],
      unique: true,
      name: INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, REDUNDANT_INDEX_NAME, if_exists: true)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      :sbom_occurrence_id,
      name: REDUNDANT_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME, if_exists: true)
  end
end
