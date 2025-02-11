# frozen_string_literal: true

class RemoveRedundantIndexOnLfsObjectProjects < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  INDEX_NAME = 'idx_lfs_objects_projects_on_project_id_lfs_object_id_repo_type'
  COLUMNS = [:project_id, :lfs_object_id, :repository_type]

  # This index was not synchronously created
  # This index was created in: ScheduleUniqueIndexLfsObjectsProjects
  # This was made redundant by:
  # - ScheduleUniqueIndexLfsObjectsProjectsWithoutRepositoryType
  # - ScheduleUniqueIndexLfsObjectsProjectsWithRepositoryType

  def up
    prepare_async_index_removal :lfs_objects_projects, COLUMNS, name: INDEX_NAME
  end

  def down
    unprepare_async_index :lfs_objects_projects, COLUMNS, name: INDEX_NAME
  end
end
