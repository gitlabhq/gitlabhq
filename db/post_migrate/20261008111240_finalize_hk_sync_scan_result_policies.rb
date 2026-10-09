# frozen_string_literal: true

class FinalizeHkSyncScanResultPolicies < Gitlab::Database::Migration[2.4]
  milestone '19.5'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'SyncScanResultPolicies',
      table_name: :security_orchestration_policy_configurations,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
