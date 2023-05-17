# frozen_string_literal: true

class AddIndexToSecurityScansOnPipelineIdAndScanType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_security_scans_on_pipeline_id_and_scan_type'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_scans, [:pipeline_id, :scan_type], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_scans, name: INDEX_NAME
  end
end
