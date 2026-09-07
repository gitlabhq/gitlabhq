# frozen_string_literal: true

class ValidateIdempotencyKeyLimitOnDuoWorkflowsWorkflowMergeRequests < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  def up
    validate_text_limit :duo_workflows_workflow_merge_requests, :idempotency_key,
      constraint_name: 'check_duo_wf_wf_mrs_idempotency_key_limit'
  end

  def down
    # no-op: validate_text_limit is not reversible
  end
end
