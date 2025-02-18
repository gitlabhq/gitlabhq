# frozen_string_literal: true

class ScheduleUniqueIndexLfsObjectsProjectsWithRepositoryType < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/467120
  INDEX_NAME = 'lfs_objects_projects_on_project_id_lfs_object_id_with_repo_type'

  def up
    prepare_async_index(
      :lfs_objects_projects,
      [
        :project_id,
        :lfs_object_id,
        :repository_type
      ],
      name: INDEX_NAME,
      unique: true,
      where: 'repository_type IS NOT NULL'
    )
  end

  def down
    unprepare_async_index(
      :lfs_objects_projects,
      [
        :project_id,
        :lfs_object_id,
        :repository_type
      ],
      name: INDEX_NAME,
      unique: true,
      where: 'repository_type IS NOT NULL'
    )
  end
end
