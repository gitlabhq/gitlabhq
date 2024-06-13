# frozen_string_literal: true

class IndexSbomOccurrencesVulnerabilitiesOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_sbom_occurrences_vulnerabilities_on_project_id'

  def up
    add_concurrent_index :sbom_occurrences_vulnerabilities, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences_vulnerabilities, INDEX_NAME
  end
end
