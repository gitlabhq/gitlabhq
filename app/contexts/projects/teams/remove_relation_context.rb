module Projects
  module Teams
    class RemoveRelationContext < Projects::BaseContext
      def execute
        team = project.user_teams.find_by_path(params[:id])
        team.resign_from_project(project)

        Teams::Projects::RemoveRelationContext.new(@current_user, team, project).execute
      end
    end
  end
end
