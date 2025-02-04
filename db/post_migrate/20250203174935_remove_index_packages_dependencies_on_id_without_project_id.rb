# frozen_string_literal: true

class RemoveIndexPackagesDependenciesOnIdWithoutProjectId < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  INDEX_NAME = :tmp_index_packages_dependencies_on_id_without_project_id

  def up
    remove_concurrent_index_by_name(:packages_dependencies, INDEX_NAME)
  end

  def down
    add_concurrent_index(:packages_dependencies, :id, name: INDEX_NAME, where: 'project_id IS NULL')
  end
end
