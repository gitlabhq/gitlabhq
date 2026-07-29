# frozen_string_literal: true

class AddFkAgentIdentityIdToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(
      :duo_workflows_workflows,
      :ai_agent_identities,
      column: :agent_identity_id,
      on_delete: :nullify,
      validate: false
    )
    validate_foreign_key :duo_workflows_workflows, :agent_identity_id
  end

  def down
    remove_foreign_key_if_exists :duo_workflows_workflows, column: :agent_identity_id
  end
end
