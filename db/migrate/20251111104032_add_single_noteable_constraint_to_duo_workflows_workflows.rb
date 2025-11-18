# frozen_string_literal: true

class AddSingleNoteableConstraintToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '18.6'

  CONSTRAINT_NAME = 'check_workflows_single_noteable'

  def up
    add_check_constraint :duo_workflows_workflows,
      'num_nonnulls(issue_id, merge_request_id) <= 1',
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :duo_workflows_workflows, CONSTRAINT_NAME
  end
end
