# frozen_string_literal: true

class AddAgentTypeToDuoWorkflowSessionArtifacts < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :duo_workflow_session_artifacts, :agent_type, :text, if_not_exists: true
    end

    add_text_limit :duo_workflow_session_artifacts, :agent_type, 50
  end

  def down
    with_lock_retries do
      remove_column :duo_workflow_session_artifacts, :agent_type, if_exists: true
    end
  end
end
