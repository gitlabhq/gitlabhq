module ProjectsHelper
  def view_mode_style(type)
    cookies["project_view"] ||= "tile"
    cookies["project_view"] == type ? nil : "display:none"
  end

  def noteable_link(id, type, project)
    case type
    when "Issue"
      link_to "Issue ##{id}", project_issue_path(project, id)
    when "Commit"
      commit = project.repo.commits(id).first
      link_to truncate(commit.id,:length => 10), project_commit_path(project, id)
    else
      link_to "Wall", wall_project_path(project)
    end
  end
end
