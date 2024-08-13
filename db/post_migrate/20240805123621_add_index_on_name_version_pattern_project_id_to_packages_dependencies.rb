# frozen_string_literal: true

class AddIndexOnNameVersionPatternProjectIdToPackagesDependencies < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.3'

  INDEX_NAME = :idx_packages_dependencies_on_name_version_pattern_project_id

  def up
    add_concurrent_index :packages_dependencies, %i[name version_pattern project_id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_dependencies, INDEX_NAME
  end
end
