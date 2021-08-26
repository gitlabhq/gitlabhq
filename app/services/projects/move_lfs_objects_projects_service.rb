# frozen_string_literal: true

module Projects
  class MoveLfsObjectsProjectsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction do
        move_lfs_objects_projects
        remove_remaining_lfs_objects_project if remove_remaining_elements

        success
      end
    end

    private

    def move_lfs_objects_projects
      non_existent_lfs_objects_projects.update_all(project_id: @project.id)
    end

    def remove_remaining_lfs_objects_project
      source_project.lfs_objects_projects.destroy_all # rubocop: disable Cop/DestroyAll
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def non_existent_lfs_objects_projects
      source_project.lfs_objects_projects.where.not(lfs_object: @project.lfs_objects)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
