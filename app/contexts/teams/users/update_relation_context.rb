module Teams
  module Users
    class UpdateRelationContext < Teams::Users::BaseContext
      def execute
        member_params = params[:team_member]

        options = {
          default_projects_access: member_params[:permission],
          group_admin: member_params[:group_admin]
        }

        result = @team.update_membership(@user, options)

        result
      end
    end
  end
end
