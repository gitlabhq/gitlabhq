# frozen_string_literal: true

class AddTargetProjectForeignKeyToMergeRequestApprovalMetrics < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_request_approval_metrics, :projects, column: :target_project_id,
      on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :merge_request_approval_metrics, :projects, column: :target_project_id,
        on_delete: :cascade
    end
  end
end
