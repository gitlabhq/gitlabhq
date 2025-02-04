# frozen_string_literal: true

class RemoveIndexPackagesDependenciesOnNameVersionPattern < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = :tmp_idx_packages_dependencies_on_name_version_pattern

  def up
    remove_concurrent_index_by_name(:packages_dependencies, INDEX_NAME)
  end

  def down
    add_concurrent_index(
      :packages_dependencies,
      %i[name version_pattern],
      unique: true,
      name: INDEX_NAME,
      where: 'project_id IS NULL'
    )
  end
end
