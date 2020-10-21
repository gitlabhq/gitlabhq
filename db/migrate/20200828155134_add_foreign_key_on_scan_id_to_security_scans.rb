# frozen_string_literal: true

class AddForeignKeyOnScanIdToSecurityScans < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_foreign_key :security_findings, :security_scans, column: :scan_id, on_delete: :cascade
    end
  end

  def down
    with_lock_retries do
      remove_foreign_key :security_findings, column: :scan_id
    end
  end
end
