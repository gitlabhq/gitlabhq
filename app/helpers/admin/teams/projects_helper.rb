module Admin::Teams::ProjectsHelper
  def assigned_since(team, project)
    team.user_team_project_relationships.find_by_project_id(project).created_at
  end
end
