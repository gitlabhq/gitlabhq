# NOTE: This service cannot be used directly because it is part of a
# a bigger process. Instead, use the service MoveAccessService which moves
# project memberships, project group links, authorizations and refreshes
# the authorizations if neccessary
module Projects
  class MoveProjectMembersService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction(requires_new: true) do
        move_project_members
        remove_remaining_members if remove_remaining_elements

        success
      end
    end

    private

    def move_project_members
      prepare_relation(non_existent_members).update_all(source_id: @project.id)
    end

    def remove_remaining_members
      # Remove remaining members and authorizations from source_project
      source_project.project_members.destroy_all
    end

    def project_members_in_target_project
      @project.project_members.select(:user_id)
    end

    # Look for members in source_project that are not in the target project
    def non_existent_members
      source_project.members
                    .select(:id)
                    .where.not(user_id: @project.project_members.select(:user_id))
    end
  end
end
