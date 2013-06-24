module Teams
  module Projects
    class CreateRelationContext < Teams::BaseContext
      def execute
        project_ids = params[:project_ids]
        access = params[:greatest_project_access]

        allowed_project_ids = current_user.owned_projects.map(&:id)
        project_ids.select! { |id| allowed_project_ids.include?(id.to_i) }

        project_ids.each do |project|
          Gitlab::UserTeamManager.assign(team, project, access)
        end
      end
    end
  end
end
