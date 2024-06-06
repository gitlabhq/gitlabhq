# frozen_string_literal: true

class IndexDastPreScanVerificationsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.1'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dast_pre_scan_verifications_on_project_id'

  def up
    add_concurrent_index :dast_pre_scan_verifications, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dast_pre_scan_verifications, INDEX_NAME
  end
end
