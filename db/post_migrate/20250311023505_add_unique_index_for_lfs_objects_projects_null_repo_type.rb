# frozen_string_literal: true

class AddUniqueIndexForLfsObjectsProjectsNullRepoType < Gitlab::Database::Migration[2.2]
  milestone '17.10'
  disable_ddl_transaction!

  TABLE_NAME = :lfs_objects_projects
  INDEX_NAME = 'lfs_objects_projects_on_project_id_lfs_object_id_null_repo_type'

  def up
    add_concurrent_index TABLE_NAME, [:project_id, :lfs_object_id],
      unique: true,
      where: "repository_type IS NULL",
      name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name TABLE_NAME, INDEX_NAME
  end
end
