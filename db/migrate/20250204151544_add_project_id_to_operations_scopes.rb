# frozen_string_literal: true

class AddProjectIdToOperationsScopes < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :operations_scopes, :project_id, :bigint
  end
end
