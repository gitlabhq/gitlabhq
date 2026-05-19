# frozen_string_literal: true

class UpdateUniqueIndexOnSbomOccurrencesVulnerabilities < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.0'

  TABLE_NAME = :sbom_occurrences_vulnerabilities
  NEW_INDEX_NAME = :i_sbom_occ_vulns_on_occ_id_vuln_id_and_project_id
  OLD_INDEX_NAME = :i_sbom_occurrences_vulnerabilities_on_occ_id_and_vuln_id

  def up
    add_concurrent_index(
      TABLE_NAME,
      %i[sbom_occurrence_id vulnerability_id project_id],
      unique: true,
      name: NEW_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(
      TABLE_NAME,
      %i[sbom_occurrence_id vulnerability_id],
      unique: true,
      name: OLD_INDEX_NAME
    )

    remove_concurrent_index_by_name(TABLE_NAME, NEW_INDEX_NAME)
  end
end
