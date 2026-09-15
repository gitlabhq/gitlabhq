# frozen_string_literal: true

class AddDuoWorkflowIdToMergeRequestsRiskAssessments < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  TABLE_NAME = :merge_requests_risk_assessments
  COLUMN_NAME = :duo_workflow_id
  INDEX_NAME = 'index_mr_risk_assessments_on_duo_workflow_id'
  FK_NAME = 'fk_mr_risk_assessments_on_duo_workflow_id'

  def up
    add_column TABLE_NAME, COLUMN_NAME, :bigint

    add_concurrent_index TABLE_NAME, COLUMN_NAME, name: INDEX_NAME

    add_concurrent_foreign_key TABLE_NAME, :duo_workflows_workflows, column: COLUMN_NAME,
      on_delete: :nullify, name: FK_NAME
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists TABLE_NAME, column: COLUMN_NAME, name: FK_NAME
    end

    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME

    remove_column TABLE_NAME, COLUMN_NAME
  end
end
