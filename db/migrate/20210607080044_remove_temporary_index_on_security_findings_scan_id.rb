# frozen_string_literal: true

class RemoveTemporaryIndexOnSecurityFindingsScanId < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_index_on_security_findings_scan_id'

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :security_findings, INDEX_NAME
  end

  def down
    add_concurrent_index :security_findings, :scan_id, where: 'uuid is null', name: INDEX_NAME
  end
end
