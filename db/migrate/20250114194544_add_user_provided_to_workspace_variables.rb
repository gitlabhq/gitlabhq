# frozen_string_literal: true

class AddUserProvidedToWorkspaceVariables < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :workspace_variables, :user_provided, :boolean, null: false, default: false, if_not_exists: true
  end
end
