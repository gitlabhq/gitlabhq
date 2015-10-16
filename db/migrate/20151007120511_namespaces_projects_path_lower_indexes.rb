class NamespacesProjectsPathLowerIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    execute 'CREATE INDEX CONCURRENTLY index_on_namespaces_lower_path ON namespaces (LOWER(path));'
    execute 'CREATE INDEX CONCURRENTLY index_on_projects_lower_path ON projects (LOWER(path));'
  end

  def down
    return unless Gitlab::Database.postgresql?

    remove_index :namespaces, name: :index_on_namespaces_lower_path
    remove_index :projects, name: :index_on_projects_lower_path
  end
end
