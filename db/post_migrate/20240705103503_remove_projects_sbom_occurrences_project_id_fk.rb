# frozen_string_literal: true

class RemoveProjectsSbomOccurrencesProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_157506c0e2"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:sbom_occurrences, :projects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:sbom_occurrences, :projects,
      name: FOREIGN_KEY_NAME, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
