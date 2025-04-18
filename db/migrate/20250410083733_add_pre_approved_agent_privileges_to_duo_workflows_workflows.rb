# frozen_string_literal: true

class AddPreApprovedAgentPrivilegesToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  READ_WRITE_FILES = 1
  READ_ONLY_GITLAB = 2

  def change
    add_column :duo_workflows_workflows, :pre_approved_agent_privileges, :smallint, array: true,
      default: [READ_WRITE_FILES, READ_ONLY_GITLAB], null: false
  end
end
