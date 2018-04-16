module Projects
  class MoveUsersStarProjectsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      user_stars = source_project.users_star_projects

      return unless user_stars.any?

      Project.transaction(requires_new: true) do
        user_stars.update_all(project_id: @project.id)

        Project.reset_counters @project.id, :users_star_projects
        Project.reset_counters source_project.id, :users_star_projects

        success
      end
    end
  end
end
