# frozen_string_literal: true

class AddPackagesDebianGroupComponentsGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_debian_group_components,
      sharding_key: :group_id,
      parent_table: :packages_debian_group_distributions,
      parent_sharding_key: :group_id,
      foreign_key: :distribution_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_debian_group_components,
      sharding_key: :group_id,
      parent_table: :packages_debian_group_distributions,
      parent_sharding_key: :group_id,
      foreign_key: :distribution_id
    )
  end
end
