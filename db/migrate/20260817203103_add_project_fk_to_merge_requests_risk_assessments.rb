# frozen_string_literal: true

# Added in a separate migration from the table creation so that only one
# table is locked at a time.
class AddProjectFkToMergeRequestsRiskAssessments < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests_risk_assessments

  def up
    add_concurrent_foreign_key TABLE_NAME, :projects, column: :project_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, :projects, column: :project_id
    end
  end
end
