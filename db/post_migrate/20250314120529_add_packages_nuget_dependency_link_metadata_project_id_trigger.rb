# frozen_string_literal: true

class AddPackagesNugetDependencyLinkMetadataProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def up
    install_sharding_key_assignment_trigger(
      table: :packages_nuget_dependency_link_metadata,
      sharding_key: :project_id,
      parent_table: :packages_dependency_links,
      parent_sharding_key: :project_id,
      foreign_key: :dependency_link_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :packages_nuget_dependency_link_metadata,
      sharding_key: :project_id,
      parent_table: :packages_dependency_links,
      parent_sharding_key: :project_id,
      foreign_key: :dependency_link_id
    )
  end
end
