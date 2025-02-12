# frozen_string_literal: true

class AddDesignManagementRepositoryStatesNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    install_sharding_key_assignment_trigger(
      table: :design_management_repository_states,
      sharding_key: :namespace_id,
      parent_table: :design_management_repositories,
      parent_sharding_key: :namespace_id,
      foreign_key: :design_management_repository_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :design_management_repository_states,
      sharding_key: :namespace_id,
      parent_table: :design_management_repositories,
      parent_sharding_key: :namespace_id,
      foreign_key: :design_management_repository_id
    )
  end
end
