# frozen_string_literal: true

class CreateScanIdAndIdIndexOnSecurityFindings < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_security_findings_on_scan_id_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_findings, [:scan_id, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end
end
