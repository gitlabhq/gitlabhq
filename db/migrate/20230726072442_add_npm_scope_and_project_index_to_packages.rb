# frozen_string_literal: true

class AddNpmScopeAndProjectIndexToPackages < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'idx_packages_packages_on_npm_scope_and_project_id'

  def up
    add_concurrent_index :packages_packages,
      "split_part(name, '/', 1), project_id",
      where: "package_type = 2 AND position('/' in name) > 0 AND status IN (0, 3) AND version IS NOT NULL",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_packages, INDEX_NAME
  end
end
