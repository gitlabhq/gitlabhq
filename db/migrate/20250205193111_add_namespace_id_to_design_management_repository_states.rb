# frozen_string_literal: true

class AddNamespaceIdToDesignManagementRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :design_management_repository_states, :namespace_id, :bigint
  end
end
