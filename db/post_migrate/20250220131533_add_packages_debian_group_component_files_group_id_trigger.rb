# frozen_string_literal: true

class AddPackagesDebianGroupComponentFilesGroupIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_debian_group_component_files,
      sharding_key: :group_id,
      parent_table: :packages_debian_group_components,
      parent_sharding_key: :group_id,
      foreign_key: :component_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_debian_group_component_files,
      sharding_key: :group_id,
      parent_table: :packages_debian_group_components,
      parent_sharding_key: :group_id,
      foreign_key: :component_id
    )
  end
end
