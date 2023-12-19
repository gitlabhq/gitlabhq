# frozen_string_literal: true

class AddForeignKeyOnSbomOccurrencesVulnerabilitiesOccurrenceId < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :sbom_occurrences_vulnerabilities,
      :sbom_occurrences,
      column: :sbom_occurrence_id,
      on_delete: :cascade
  end

  def down
    remove_foreign_key :sbom_occurrences_vulnerabilities,
      to_table: :sbom_occurrences,
      column: :sbom_occurrence_id,
      on_delete: :cascade
  end
end
