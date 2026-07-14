# frozen_string_literal: true

class AddIndexSbomOccurrencesVulnerabilitiesOnSbomOccurrenceRefId < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  disable_ddl_transaction!

  INDEX_NAME = 'idx_sbom_occ_vulns_on_sbom_occurrence_ref_id'

  def up
    add_concurrent_index :sbom_occurrences_vulnerabilities, :sbom_occurrence_ref_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences_vulnerabilities, INDEX_NAME
  end
end
