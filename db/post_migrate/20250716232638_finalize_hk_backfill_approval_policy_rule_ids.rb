# frozen_string_literal: true

class FinalizeHkBackfillApprovalPolicyRuleIds < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillApprovalPolicyRuleIds',
      table_name: :scan_result_policies,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
