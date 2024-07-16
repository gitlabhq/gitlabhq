# frozen_string_literal: true

class AddPackagesDebianProjectArchitecturesProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_debian_project_architectures,
      sharding_key: :project_id,
      parent_table: :packages_debian_project_distributions,
      parent_sharding_key: :project_id,
      foreign_key: :distribution_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_debian_project_architectures,
      sharding_key: :project_id,
      parent_table: :packages_debian_project_distributions,
      parent_sharding_key: :project_id,
      foreign_key: :distribution_id
    )
  end
end
