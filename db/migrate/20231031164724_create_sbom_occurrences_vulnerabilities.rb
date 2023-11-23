# frozen_string_literal: true

class CreateSbomOccurrencesVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  INDEX_NAME = 'i_sbom_occurrences_vulnerabilities_on_occ_id_and_vuln_id'

  def change
    create_table :sbom_occurrences_vulnerabilities do |t|
      t.references :sbom_occurrence, null: false, index: false
      t.references :vulnerability, null: false, index: true
      t.timestamps_with_timezone null: false
      t.index [:sbom_occurrence_id, :vulnerability_id], unique: true, name: INDEX_NAME
    end
  end
end
