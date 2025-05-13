# frozen_string_literal: true

class FinalizeBackfillPipelineExecutionPolicyConfigLinks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.0'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    ensure_batched_background_migration_is_finished(
      job_class_name: 'BackfillPipelineExecutionPoliciesConfigLinks',
      table_name: :security_policies,
      column_name: :id,
      job_arguments: [],
      finalize: true
    )
  end

  def down; end
end
