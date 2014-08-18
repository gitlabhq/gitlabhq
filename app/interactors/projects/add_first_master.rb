module Projects
  class AddFirstMaster < Projects::Base
    def setup
      super

      context.fail!(message: "User not exist") if context[:user].blank?
    end

    # If project created not in group
    # And no members in them
    # Add current user with 'Master' role
    def perform
      project = context[:project]
      current_user = context[:user]

      if project.group.blank? && project.users_projects.empty?
        project.users_projects.create(
          project_access: UsersProject::MASTER,
          user: current_user
        )
      end
    end

    def rollback
      project = context[:project]
      current_user = context[:user]

      project.users_projects.find_by(user_id: current_user.id).destroy
    end
  end
end
