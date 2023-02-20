# frozen_string_literal: true

class AllowNullPipelineIdToDastPreScanVerification < Gitlab::Database::Migration[2.1]
  def up
    change_column_null :dast_pre_scan_verifications, :ci_pipeline_id, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
