module MergeRequestsHelper
  def link_to_merge_request_assignee(merge_request)
    project = merge_request.project

    tm = project.team_member_by_id(merge_request.assignee_id)
    if tm
      link_to merge_request.assignee_name, project_team_member_path(project, tm), :class => "author_link"
    else
      merge_request.assignee_name
    end
  end

  def link_to_merge_request_author(merge_request)
    project = merge_request.project

    tm = project.team_member_by_id(merge_request.author_id)
    if tm
      link_to merge_request.author_name, project_team_member_path(project, tm), :class => "author_link"
    else
      merge_request.author_name
    end
  end
end
