# frozen_string_literal: true

class AddIndexToSecurityScansOnScanType < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  TABLE_NAME = :security_scans
  INDEX_NAME = 'index_for_security_scans_scan_type'
  SUCCEEDED = 1

  def up
    add_concurrent_index TABLE_NAME, [:scan_type, :project_id, :pipeline_id], where: "status = #{SUCCEEDED}",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
