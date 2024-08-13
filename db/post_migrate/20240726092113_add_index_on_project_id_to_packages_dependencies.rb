# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexOnProjectIdToPackagesDependencies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = :index_packages_dependencies_on_project_id

  def up
    add_concurrent_index :packages_dependencies, :project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_dependencies, INDEX_NAME
  end
end
