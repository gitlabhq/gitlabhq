# frozen_string_literal: true

class UpdateDesignManagementDesignsNamespaceIdTrigger < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def up
    # Remove the projects.namespace_id trigger
    remove_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :namespace_id,
      foreign_key: :project_id
    )

    # Add the projects.project_namespace_id trigger
    install_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :project_namespace_id,
      foreign_key: :project_id
    )
  end

  def down
    # Remove the projects.project_namespace_id trigger
    remove_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :project_namespace_id,
      foreign_key: :project_id
    )

    # Add the projects.namespace_id trigger
    install_sharding_key_assignment_trigger(
      table: :design_management_designs,
      sharding_key: :namespace_id,
      parent_table: :projects,
      parent_sharding_key: :namespace_id,
      foreign_key: :project_id
    )
  end
end
