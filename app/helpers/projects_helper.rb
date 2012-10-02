module ProjectsHelper
  def grouper_project_members(project)
    @project.users_projects.sort_by(&:project_access).reverse.group_by(&:project_access)
  end

  def remove_from_team_message(project, member)
    "You are going to remove #{member.user_name} from #{project.name}. Are you sure?"
  end

  def link_to_project project
    link_to project.name, project
  end
end

