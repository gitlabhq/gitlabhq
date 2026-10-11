# frozen_string_literal: true

class AddDropReasonToDuoWorkflowsWorkflows < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.5'

  # No default: nil means the session was not force-failed (or predates this
  # column). A default would mislabel every non-dropped session. Text, not an
  # enum-backed smallint (see Ai::DuoWorkflows::Workflow::DROP_REASONS).
  def up
    add_column :duo_workflows_workflows, :drop_reason, :text, if_not_exists: true

    add_text_limit :duo_workflows_workflows, :drop_reason, 64
  end

  def down
    remove_column :duo_workflows_workflows, :drop_reason, if_exists: true
  end
end
