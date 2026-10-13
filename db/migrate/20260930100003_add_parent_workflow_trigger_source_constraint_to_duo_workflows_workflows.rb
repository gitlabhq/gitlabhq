# frozen_string_literal: true

class AddParentWorkflowTriggerSourceConstraintToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'check_duo_workflows_workflows_parent_workflow_id_flow'
  # Ai::DuoWorkflows::Workflow trigger_source enum value for `flow`
  FLOW_TRIGGER_SOURCE = 4

  # One direction only: `on_delete: :nullify` on the parent FK leaves children
  # with `trigger_source = flow` and no parent, which must stay valid.
  def up
    add_check_constraint :duo_workflows_workflows,
      "parent_workflow_id IS NULL OR trigger_source = #{FLOW_TRIGGER_SOURCE}",
      CONSTRAINT_NAME
  end

  def down
    remove_check_constraint :duo_workflows_workflows, CONSTRAINT_NAME
  end
end
