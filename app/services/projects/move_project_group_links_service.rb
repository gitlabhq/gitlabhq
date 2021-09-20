# frozen_string_literal: true

# NOTE: This service cannot be used directly because it is part of a
# a bigger process. Instead, use the service MoveAccessService which moves
# project memberships, project group links, authorizations and refreshes
# the authorizations if necessary
module Projects
  class MoveProjectGroupLinksService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction do
        move_group_links
        remove_remaining_project_group_links if remove_remaining_elements

        success
      end
    end

    private

    def move_group_links
      non_existent_group_links.update_all(project_id: @project.id)
    end

    # Remove remaining project group links from source_project
    def remove_remaining_project_group_links
      source_project.reset.project_group_links.destroy_all # rubocop: disable Cop/DestroyAll
    end

    def group_links_in_target_project
      @project.project_group_links.select(:group_id)
    end

    # Look for groups in source_project that are not in the target project
    # rubocop: disable CodeReuse/ActiveRecord
    def non_existent_group_links
      source_project.project_group_links
                    .where.not(group_id: group_links_in_target_project)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
