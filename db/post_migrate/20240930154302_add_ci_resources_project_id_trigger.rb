# frozen_string_literal: true

class AddCiResourcesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_resources,
      sharding_key: :project_id,
      parent_table: :ci_resource_groups,
      parent_sharding_key: :project_id,
      foreign_key: :resource_group_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_resources,
      sharding_key: :project_id,
      parent_table: :ci_resource_groups,
      parent_sharding_key: :project_id,
      foreign_key: :resource_group_id
    )
  end
end
