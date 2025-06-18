# frozen_string_literal: true

class AddDesignManagementRepositoryStatesNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.2'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :design_management_repository_states, :namespace_id
  end

  def down
    remove_not_null_constraint :design_management_repository_states, :namespace_id
  end
end
