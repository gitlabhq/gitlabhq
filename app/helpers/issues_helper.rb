module IssuesHelper
  def sort_class
    if can?(current_user, :admin_issue, @project) && (!params[:f] || params[:f] == "0")
                        "handle"
    end
  end

  def project_issues_filter_path project, params = {}
    params[:f] ||= cookies['issue_filter']
    project_issues_path project, params
  end

  def link_to_issue_assignee(issue)
    project = issue.project

    tm = project.team_member_by_id(issue.assignee_id)
    if tm
      link_to issue.assignee_name, project_team_member_path(project, tm), :class => "author_link"
    else
      issue.assignee_name
    end
  end

  def link_to_issue_author(issue)
    project = issue.project

    tm = project.team_member_by_id(issue.author_id)
    if tm
      link_to issue.author_name, project_team_member_path(project, tm), :class => "author_link"
    else
      issue.author_name
    end
  end
end
