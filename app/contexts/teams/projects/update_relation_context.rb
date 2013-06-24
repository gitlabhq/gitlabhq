module Teams
  module Projects
    class UpdateRelationContext < Teams::Projects::BaseContext
      def execute
        permission = params[:greatest_project_access]

        Gitlab::UserTeamManager.update_project_greates_access(team, project, permission)
      end
    end
  end
end
