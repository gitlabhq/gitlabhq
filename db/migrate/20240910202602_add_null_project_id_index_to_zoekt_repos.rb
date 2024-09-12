# frozen_string_literal: true

class AddNullProjectIdIndexToZoektRepos < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  INDEX_NAME = "index_zoekt_repos_with_missing_project_id"

  def up
    add_concurrent_index :zoekt_repositories, :project_id, name: INDEX_NAME, where: "project_id IS NULL"
  end

  def down
    remove_concurrent_index_by_name(:zoekt_repositories, name: INDEX_NAME)
  end
end
