# frozen_string_literal: true

class ScheduleUniqueIndexLfsObjectsProjects < Gitlab::Database::Migration[2.2]
  INDEX_NAME = 'idx_lfs_objects_projects_on_project_id_lfs_object_id_repo_type'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/467120
  milestone '17.8'
  def up
    prepare_async_index(
      :lfs_objects_projects,
      [
        :project_id,
        :lfs_object_id,
        :repository_type
      ],
      name: INDEX_NAME,
      unique: true
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
      unique: true
    )
  end
end
