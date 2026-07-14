# frozen_string_literal: true

class AddSbomOccurrenceRefIdToSbomOccurrencesVulnerabilities < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def up
    add_column :sbom_occurrences_vulnerabilities, :sbom_occurrence_ref_id, :bigint
  end

  def down
    remove_column :sbom_occurrences_vulnerabilities, :sbom_occurrence_ref_id
  end
end
