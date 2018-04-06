class MergeRequestPresenter < Gitlab::View::Presenter::Delegated
  include ActionView::Helpers::UrlHelper
  include GitlabRoutingHelper
  include MarkupHelper
  include TreeHelper
  include Gitlab::Utils::StrongMemoize

  presents :merge_request

  def ci_status
    if pipeline
      status = pipeline.status
      status = "success_with_warnings" if pipeline.success? && pipeline.has_warnings?

      status || "preparing"
    else
      ci_service = source_project.try(:ci_service)
      ci_service&.commit_status(diff_head_sha, source_branch)
    end
  end

  def cancel_merge_when_pipeline_succeeds_path
    if can_cancel_merge_when_pipeline_succeeds?(current_user)
      cancel_merge_when_pipeline_succeeds_project_merge_request_path(project, merge_request)
    end
  end

  def create_issue_to_resolve_discussions_path
    if can?(current_user, :create_issue, project) && project.issues_enabled?
      new_project_issue_path(project, merge_request_to_resolve_discussions_of: iid)
    end
  end

  def remove_wip_path
    if work_in_progress? && can?(current_user, :update_merge_request, merge_request.project)
      remove_wip_project_merge_request_path(project, merge_request)
    end
  end

  def merge_path
    if can_be_merged_by?(current_user)
      merge_project_merge_request_path(project, merge_request)
    end
  end

  def revert_in_fork_path
    if user_can_fork_project? && cached_can_be_reverted?
      continue_params = {
        to: merge_request_path(merge_request),
        notice: "#{edit_in_new_fork_notice} Try to cherry-pick this commit again.",
        notice_now: edit_in_new_fork_notice_now
      }

      project_forks_path(merge_request.project,
                                   namespace_key: current_user.namespace.id,
                                   continue: continue_params)
    end
  end

  def cherry_pick_in_fork_path
    if user_can_fork_project? && can_be_cherry_picked?
      continue_params = {
        to: merge_request_path(merge_request),
        notice: "#{edit_in_new_fork_notice} Try to revert this commit again.",
        notice_now: edit_in_new_fork_notice_now
      }

      project_forks_path(project,
                                   namespace_key: current_user.namespace.id,
                                   continue: continue_params)
    end
  end

  def conflict_resolution_path
    if conflicts.can_be_resolved_in_ui? && conflicts.can_be_resolved_by?(current_user)
      conflicts_project_merge_request_path(project, merge_request)
    end
  end

  def rebase_path
    if !rebase_in_progress? && should_be_rebased? && can_push_to_source_branch?
      rebase_project_merge_request_path(project, merge_request)
    end
  end

  def target_branch_tree_path
    if target_branch_exists?
      project_tree_path(project, target_branch)
    end
  end

  def target_branch_commits_path
    if target_branch_exists?
      project_commits_path(project, target_branch)
    end
  end

  def source_branch_path
    if source_branch_exists?
      project_branch_path(source_project, source_branch)
    end
  end

  def approvals_path
    if requires_approve?
      approvals_project_merge_request_path(project, merge_request)
    end
  end

  def source_branch_with_namespace_link
    namespace = source_project_namespace
    branch = source_branch

    if source_branch_exists?
      namespace = link_to(namespace, project_path(source_project))
      branch = link_to(branch, project_tree_path(source_project, source_branch))
    end

    if for_fork?
      namespace + ":" + branch
    else
      branch
    end
  end

  def closing_issues_links
    markdown(
      issues_sentence(project, closing_issues),
      pipeline: :gfm,
      author: author,
      project: project,
      issuable_state_filter_enabled: true
    )
  end

  def mentioned_issues_links
    mentioned_issues = issues_mentioned_but_not_closing(current_user)
    markdown(
      issues_sentence(project, mentioned_issues),
      pipeline: :gfm,
      author: author,
      project: project,
      issuable_state_filter_enabled: true
    )
  end

  def assign_to_closing_issues_link
    issues = MergeRequests::AssignIssuesService.new(project,
                                                    current_user,
                                                    merge_request: merge_request,
                                                    closes_issues: closing_issues
                                                   ).assignable_issues
    path = assign_related_issues_project_merge_request_path(project, merge_request)
    if issues.present?
      pluralize_this_issue = issues.count > 1 ? "these issues" : "this issue"
      link_to "Assign yourself to #{pluralize_this_issue}", path, method: :post
    end
  end

  def can_revert_on_current_merge_request?
    user_can_collaborate_with_project? && cached_can_be_reverted?
  end

  def can_cherry_pick_on_current_merge_request?
    user_can_collaborate_with_project? && can_be_cherry_picked?
  end

  def can_push_to_source_branch?
    return false unless source_branch_exists?

    !!::Gitlab::UserAccess
      .new(current_user, project: source_project)
      .can_push_to_branch?(source_branch)
  end

  private

  def cached_can_be_reverted?
    strong_memoize(:can_be_reverted) do
      can_be_reverted?(current_user)
    end
  end

  def conflicts
    @conflicts ||= MergeRequests::Conflicts::ListService.new(merge_request)
  end

  def closing_issues
    @closing_issues ||= closes_issues(current_user)
  end

  def pipeline
    @pipeline ||= actual_head_pipeline
  end

  def issues_sentence(project, issues)
    # Sorting based on the `#123` or `group/project#123` reference will sort
    # local issues first.
    issues.map do |issue|
      issue.to_reference(project)
    end.sort.to_sentence
  end

  def user_can_collaborate_with_project?
    can_create_merge_request =
      can?(current_user, :create_merge_request_in, project) &&
      current_user.already_forked?(project)

    can?(current_user, :push_code, project) ||
      can_create_merge_request ||
      can_push_to_source_branch?
  end

  def user_can_fork_project?
    can?(current_user, :fork_project, project)
  end
end
