# frozen_string_literal: true

class RemoveProjectsSbomOccurrencesVulnerabilitiesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_058f258503"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:sbom_occurrences_vulnerabilities, :projects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:sbom_occurrences_vulnerabilities, :projects,
      name: FOREIGN_KEY_NAME, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
