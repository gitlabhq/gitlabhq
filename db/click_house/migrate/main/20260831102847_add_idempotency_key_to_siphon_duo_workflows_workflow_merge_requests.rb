# frozen_string_literal: true

class AddIdempotencyKeyToSiphonDuoWorkflowsWorkflowMergeRequests < ClickHouse::Migration
  def up
    execute "ALTER TABLE siphon_duo_workflows_workflow_merge_requests " \
      "ADD COLUMN IF NOT EXISTS idempotency_key Nullable(String)"
  end

  def down
    execute "ALTER TABLE siphon_duo_workflows_workflow_merge_requests " \
      "DROP COLUMN IF EXISTS idempotency_key"
  end
end
