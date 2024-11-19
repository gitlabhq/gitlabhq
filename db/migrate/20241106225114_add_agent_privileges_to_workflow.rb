# frozen_string_literal: true

class AddAgentPrivilegesToWorkflow < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  READ_WRITE_FILES = 1
  READ_ONLY_GITLAB = 2

  def change
    add_column :duo_workflows_workflows, :agent_privileges, :smallint, array: true,
      default: [READ_WRITE_FILES, READ_ONLY_GITLAB], null: false
  end
end
