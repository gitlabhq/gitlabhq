# frozen_string_literal: true

class RemoveProjectsDastPreScanVerificationsProjectIdFk < Gitlab::Database::Migration[2.2]
  milestone '17.4'
  disable_ddl_transaction!

  FOREIGN_KEY_NAME = "fk_d23ad33d6e"

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dast_pre_scan_verifications, :projects,
        name: FOREIGN_KEY_NAME, reverse_lock_order: true)
    end
  end

  def down
    add_concurrent_foreign_key(:dast_pre_scan_verifications, :projects,
      name: FOREIGN_KEY_NAME, column: :project_id,
      target_column: :id, on_delete: :cascade)
  end
end
