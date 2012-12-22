module MergeRequestsHelper
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

  def ci_build_details_path merge_request
    merge_request.project.gitlab_ci_service.build_page(merge_request.last_commit.sha)
  end
end
