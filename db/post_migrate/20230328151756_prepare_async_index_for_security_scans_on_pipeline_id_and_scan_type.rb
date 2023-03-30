# frozen_string_literal: true

class PrepareAsyncIndexForSecurityScansOnPipelineIdAndScanType < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_security_scans_on_pipeline_id_and_scan_type'

  disable_ddl_transaction!

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/402978
  def up
    prepare_async_index :security_scans, [:pipeline_id, :scan_type], name: INDEX_NAME
  end

  def down
    unprepare_async_index :security_scans, [:pipeline_id, :scan_type], name: INDEX_NAME
  end
end
