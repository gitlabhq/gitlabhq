module ProjectsHelper
  def grouper_project_members(project)
    @project.users_projects.sort_by(&:project_access).reverse.group_by(&:project_access)
  end

  def remove_from_team_message(project, member)
    "You are going to remove #{member.user_name} from #{project.name}. Are you sure?"
  end

  def link_to_project project
    link_to project do
      title = content_tag(:strong, project.name)

      if project.namespace
        namespace = content_tag(:span, "#{project.namespace.human_name} / ", class: 'tiny')
        title = namespace + title
      end

      title
    end
  end

  def tm_path team_member
    project_team_member_path(@project, team_member)
  end

  def project_title project
    if project.group
      project.name_with_namespace
    else
      project.name
    end
  end
end
