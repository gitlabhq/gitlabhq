# frozen_string_literal: true

class FinalizeBackfillDastPreScanVerificationStepsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_sec

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillDastPreScanVerificationStepsProjectId',
      table_name: :dast_pre_scan_verification_steps,
      column_name: :id,
      job_arguments: [:project_id, :dast_pre_scan_verifications, :project_id, :dast_pre_scan_verification_id],
      finalize: true
    )
  end

  def down; end
end
