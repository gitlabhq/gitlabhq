# frozen_string_literal: true

class DropIndexOnSecurityFindingsUuidAndScanId < Gitlab::Database::Migration[2.0]
  INDEX_NAME = 'index_security_findings_on_uuid_and_scan_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end

  def down
    add_concurrent_index :security_findings, [:uuid, :scan_id], unique: true, name: INDEX_NAME
  end
end
