# frozen_string_literal: true

class AddForeignKeyToPartialScanId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :vulnerability_partial_scans, :security_scans, column: :scan_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :vulnerability_partial_scans, column: :scan_id
    end
  end
end
