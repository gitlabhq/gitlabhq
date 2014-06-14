module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_project_merge_request_path(
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_path_for_fork_from_push_event(event)
    new_project_merge_request_path(
      event.project,
      new_mr_from_push_event(event, event.project.forked_from_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    return :merge_request => {
      source_project_id: event.project.id,
      target_project_id: target_project.id,
      source_branch: event.branch_name,
      target_branch: target_project.repository.root_ref,
      title: event.branch_name.titleize.humanize
    }
  end

  def mr_css_classes mr
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path merge_request
    merge_request.source_project.ci_service.build_page(merge_request.last_commit.sha)
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.path_with_namespace}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  def issues_sentence(issues)
    issues.map { |i| "##{i.iid}" }.to_sentence
  end
end
