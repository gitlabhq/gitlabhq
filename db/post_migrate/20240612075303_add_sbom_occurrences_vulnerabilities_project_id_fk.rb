# frozen_string_literal: true

class AddSbomOccurrencesVulnerabilitiesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :sbom_occurrences_vulnerabilities, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :sbom_occurrences_vulnerabilities, column: :project_id
    end
  end
end
