# frozen_string_literal: true

class AddForeignKeyToMergeRequestsComplianceViolationsTargetProject < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :merge_requests_compliance_violations,
      :projects,
      column: :target_project_id,
      on_delete: :cascade,
      reverse_lock_order: true,
      validate: false
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :merge_requests_compliance_violations, column: :target_project_id,
        reverse_lock_order: true
    end
  end
end
