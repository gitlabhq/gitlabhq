module Projects
  class MoveLfsObjectsProjectsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction(requires_new: true) do
        move_lfs_objects_projects
        remove_remaining_lfs_objects_project if remove_remaining_elements

        success
      end
    end

    private

    def move_lfs_objects_projects
      prepare_relation(non_existent_lfs_objects_projects)
        .update_all(project_id: @project.lfs_storage_project.id)
    end

    def remove_remaining_lfs_objects_project
      source_project.lfs_objects_projects.destroy_all
    end

    def non_existent_lfs_objects_projects
      source_project.lfs_objects_projects.where.not(lfs_object: @project.lfs_objects)
    end
  end
end
