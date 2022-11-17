# frozen_string_literal: true

module Projects
  class MoveUsersStarProjectsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      user_stars = source_project.users_star_projects

      return unless user_stars.any?

      Project.transaction do
        user_stars.update_all(project_id: @project.id)

        @project.update(star_count: @project.starrers.with_state(:active).size)
        source_project.update(star_count: source_project.starrers.with_state(:active).size)

        success
      end
    end
  end
end
