# frozen_string_literal: true

class AddUniqueIndexOnScanIdAndPositionOfSecurityFindings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'index_security_findings_on_scan_id_and_position'

  disable_ddl_transaction!

  def up
    add_concurrent_index :security_findings, [:scan_id, :position], unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end
end
