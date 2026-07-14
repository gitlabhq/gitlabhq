# frozen_string_literal: true

class AddFkSbomOccurrencesVulnerabilitiesToSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :sbom_occurrences_vulnerabilities, :sbom_occurrence_refs,
      column: :sbom_occurrence_ref_id, on_delete: :cascade
  end

  def down
    remove_foreign_key_if_exists :sbom_occurrences_vulnerabilities, column: :sbom_occurrence_ref_id
  end
end
