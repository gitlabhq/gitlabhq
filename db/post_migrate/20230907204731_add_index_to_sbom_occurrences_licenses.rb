# frozen_string_literal: true

class AddIndexToSbomOccurrencesLicenses < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_sbom_occurrences_on_licenses_spdx_identifier"

  disable_ddl_transaction!

  def up
    return if index_exists_by_name?(:sbom_occurrences, INDEX_NAME)

    disable_statement_timeout do
      execute <<~SQL
      CREATE INDEX CONCURRENTLY #{INDEX_NAME}
      ON sbom_occurrences
      USING BTREE (project_id, (licenses#>'{0,spdx_identifier}'), (licenses#>'{1,spdx_identifier}'))
      SQL
    end
  end

  def down
    remove_concurrent_index_by_name :sbom_occurrences, INDEX_NAME
  end
end
