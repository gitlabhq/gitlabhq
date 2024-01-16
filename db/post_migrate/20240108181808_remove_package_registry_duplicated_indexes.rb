# frozen_string_literal: true

class RemovePackageRegistryDuplicatedIndexes < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '16.8'

  DUPLICATED_INDEXES = [
    {
      name: :index_packages_debian_group_distributions_on_group_id,
      table: :packages_debian_group_distributions,
      column: :group_id
    },
    {
      name: :index_packages_debian_project_distributions_on_project_id,
      table: :packages_debian_project_distributions,
      column: :project_id
    },
    {
      name: :index_packages_tags_on_package_id,
      table: :packages_tags,
      column: :package_id
    }
  ]

  def up
    DUPLICATED_INDEXES.each do |index|
      remove_concurrent_index_by_name(index[:table], index[:name])
    end
  end

  def down
    DUPLICATED_INDEXES.each do |index|
      add_concurrent_index(index[:table], index[:column], name: index[:name])
    end
  end
end
