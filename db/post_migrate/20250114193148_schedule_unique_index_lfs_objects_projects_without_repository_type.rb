# frozen_string_literal: true

class ScheduleUniqueIndexLfsObjectsProjectsWithoutRepositoryType < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/467120
  INDEX_NAME = 'lfs_objects_projects_on_project_id_lfs_object_id_null_repo_type'

  def up
    prepare_async_index(
      :lfs_objects_projects,
      [
        :project_id,
        :lfs_object_id
      ],
      name: INDEX_NAME,
      unique: true,
      where: 'repository_type IS NULL'
    )
  end

  def down
    unprepare_async_index(
      :lfs_objects_projects,
      [
        :project_id,
        :lfs_object_id
      ],
      name: INDEX_NAME,
      unique: true,
      where: 'repository_type IS NULL'
    )
  end
end
