# frozen_string_literal: true

# NOTE: This service cannot be used directly because it is part of a
# a bigger process. Instead, use the service MoveAccessService which moves
# project memberships, project group links, authorizations and refreshes
# the authorizations if necessary
module Projects
  class MoveProjectAuthorizationsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      Project.transaction do
        move_project_authorizations

        remove_remaining_authorizations if remove_remaining_elements

        success
      end
    end

    private

    def move_project_authorizations
      non_existent_authorization.update_all(project_id: @project.id)
    end

    def remove_remaining_authorizations
      # I think because the Project Authorization table does not have a primary key
      # it brings a lot a problems/bugs. First, Rails raises PG::SyntaxException if we use
      # destroy_all instead of delete_all.
      source_project.project_authorizations.delete_all(:delete_all)
    end

    # Look for authorizations in source_project that are not in the target project
    # rubocop: disable CodeReuse/ActiveRecord
    def non_existent_authorization
      source_project.project_authorizations
                    .select(:user_id)
                    .where.not(user: @project.authorized_users)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
