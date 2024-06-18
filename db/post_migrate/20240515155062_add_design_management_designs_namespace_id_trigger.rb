# frozen_string_literal: true

class AddDesignManagementDesignsNamespaceIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def up
    install_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :namespace_id,
      foreign_key: :project_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :namespace_id,
      foreign_key: :project_id
    )
  end
end
