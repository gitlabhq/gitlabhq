# frozen_string_literal: true

class AddFkOnSbomOccurrenceRefsForSbomOccurrences < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_concurrent_index :sbom_occurrence_refs,
      :sbom_occurrence_id,
      name: 'idx_sbom_occurrence_refs_on_occurrence_id'
    add_concurrent_foreign_key :sbom_occurrence_refs, :sbom_occurrences, column: :sbom_occurrence_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_occurrence_refs, column: :sbom_occurrence_id
    end
    remove_concurrent_index_by_name :sbom_occurrence_refs, 'idx_sbom_occurrence_refs_on_occurrence_id'
  end
end
