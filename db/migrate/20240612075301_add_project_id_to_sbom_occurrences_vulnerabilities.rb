# frozen_string_literal: true

class AddProjectIdToSbomOccurrencesVulnerabilities < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :sbom_occurrences_vulnerabilities, :project_id, :bigint
  end
end
