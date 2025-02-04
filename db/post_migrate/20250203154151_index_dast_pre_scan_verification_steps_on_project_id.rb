# frozen_string_literal: true

class IndexDastPreScanVerificationStepsOnProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_dast_pre_scan_verification_steps_on_project_id'

  def up
    add_concurrent_index :dast_pre_scan_verification_steps, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dast_pre_scan_verification_steps, INDEX_NAME
  end
end
