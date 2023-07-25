# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class IndexProjectsOnNamespaceIdAndRepositorySizeLimit < Gitlab::Database::Migration[2.1]
  INDEX_NAME = "index_projects_on_namespace_id_and_repository_size_limit"

  disable_ddl_transaction!

  def up
    add_concurrent_index :projects, [:namespace_id, :repository_size_limit], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :projects, [:namespace_id, :repository_size_limit], name: INDEX_NAME
  end
end
