module MergeRequestsHelper
  def link_to_merge_request_assignee(merge_request)
    project = merge_request.project

    tm = project.team_member_by_id(merge_request.assignee_id)
    if tm
      link_to merge_request.assignee_name, project_team_member_path(project, tm), class: "author_link"
    else
      merge_request.assignee_name
    end
  end

  def link_to_merge_request_author(merge_request)
    project = merge_request.project

    tm = project.team_member_by_id(merge_request.author_id)
    if tm
      link_to merge_request.author_name, project_team_member_path(project, tm), class: "author_link"
    else
      merge_request.author_name
    end
  end

  def new_mr_path_from_push_event(event)
    new_project_merge_request_path(
      event.project,
      merge_request: {
        source_branch: event.branch_name,
        target_branch: event.project.root_ref,
        title: event.branch_name.titleize
      }
    )
  end

  def mr_css_classes mr
    classes = "merge_request"
    classes << " closed" if mr.closed
    classes << " merged" if mr.merged?
    classes
  end
end
