module MergeRequestsHelper
  def new_mr_path_from_push_event(event)
    target_project = event.project.forked_from_project || event.project
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, target_project)
    )
  end

  def new_mr_path_for_fork_from_push_event(event)
    new_namespace_project_merge_request_path(
      event.project.namespace,
      event.project,
      new_mr_from_push_event(event, event.project.forked_from_project)
    )
  end

  def new_mr_from_push_event(event, target_project)
    {
      merge_request: {
        source_project_id: event.project.id,
        target_project_id: target_project.id,
        source_branch: event.branch_name,
        target_branch: target_project.repository.root_ref
      }
    }
  end

  def mr_css_classes(mr)
    classes = "merge-request"
    classes << " closed" if mr.closed?
    classes << " merged" if mr.merged?
    classes
  end

  def ci_build_details_path(merge_request)
    merge_request.source_project.ci_service.build_page(merge_request.last_commit.sha, merge_request.source_branch)
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

  def mr_change_branches_path(merge_request)
    new_namespace_project_merge_request_path(
      @project.namespace, @project,
      merge_request: {
        source_project_id: @merge_request.source_project_id,
        target_project_id: @merge_request.target_project_id,
        source_branch: @merge_request.source_branch,
        target_branch: nil
      }
    )
  end

  def source_branch_with_namespace(merge_request)
    if merge_request.for_fork?
      namespace = link_to(merge_request.source_project_namespace,
        project_path(merge_request.source_project))
      namespace + ":#{merge_request.source_branch}"
    else
      merge_request.source_branch
    end
  end
end
