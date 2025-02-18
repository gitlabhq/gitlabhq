# frozen_string_literal: true

class MergeRequestPresenter < Gitlab::View::Presenter::Delegated
  include GitlabRoutingHelper
  include MarkupHelper
  include TreeHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize

  delegator_override_with Gitlab::Utils::StrongMemoize # This module inclusion is expected. See https://gitlab.com/gitlab-org/gitlab/-/issues/352884.

  APPROVALS_WIDGET_BASE_TYPE = 'base'

  presents ::MergeRequest, as: :merge_request

  def ci_status
    if pipeline
      status = pipeline.status
      status = "success-with-warnings" if pipeline.success? && pipeline.has_warnings?

      status || "preparing"
    else
      ci_integration = source_project.try(:ci_integration)
      ci_integration&.commit_status(diff_head_sha, source_branch)
    end
  end

  def cancel_auto_merge_path
    if can_cancel_auto_merge?(current_user)
      cancel_auto_merge_project_merge_request_path(project, merge_request)
    end
  end

  def create_issue_to_resolve_discussions_path
    if can?(current_user, :create_issue, project) && project.issues_enabled?
      new_project_issue_path(project, merge_request_to_resolve_discussions_of: iid, merge_request_id: id)
    end
  end

  def remove_wip_path
    if can?(current_user, :update_merge_request, merge_request.project)
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
        notice: _('%{edit_in_new_fork_notice} Try to cherry-pick this commit again.') % { edit_in_new_fork_notice: edit_in_new_fork_notice },
        notice_now: edit_in_new_fork_notice_now
      }

      project_forks_path(merge_request.project, namespace_key: current_user.namespace.id, continue: continue_params)
    end
  end

  def cherry_pick_in_fork_path
    if user_can_fork_project? && can_be_cherry_picked?
      continue_params = {
        to: merge_request_path(merge_request),
        notice: _('%{edit_in_new_fork_notice} Try to revert this commit again.') % { edit_in_new_fork_notice: edit_in_new_fork_notice },
        notice_now: edit_in_new_fork_notice_now
      }

      project_forks_path(project, namespace_key: current_user.namespace.id, continue: continue_params)
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

  def target_branch_path
    if target_branch_exists?
      project_branch_path(project, target_branch)
    end
  end

  def source_branch_commits_path
    if source_branch_exists?
      project_commits_path(source_project, source_branch)
    end
  end

  def source_branch_path
    if source_branch_exists?
      project_branch_path(source_project, source_branch)
    end
  end

  def source_branch_with_namespace_link
    namespace = source_project_namespace
    branch = source_branch

    namespace_link = source_branch_exists? ? link_to(namespace, project_path(source_project)) : ERB::Util.html_escape(namespace)
    branch_link = source_branch_exists? ? link_to(branch, project_tree_path(source_project, source_branch)) : ERB::Util.html_escape(branch)

    for_fork? ? "#{namespace_link}:#{branch_link}" : branch_link
  end

  def closing_issues_links
    markdown(
      issues_sentence(project, closing_issues),
      pipeline: :gfm,
      author: author,
      project: project,
      issuable_reference_expansion_enabled: true
    )
  end

  def mentioned_issues_links
    markdown(
      issues_sentence(project, mentioned_issues),
      pipeline: :gfm,
      author: author,
      project: project,
      issuable_reference_expansion_enabled: true
    )
  end

  def assign_to_closing_issues_path
    assign_related_issues_project_merge_request_path(project, merge_request)
  end

  def assign_to_closing_issues_count
    # rubocop: disable CodeReuse/ServiceClass
    issues = MergeRequests::AssignIssuesService.new(
      project: project,
      current_user: current_user,
      params: { merge_request: merge_request, closes_issues: closing_issues }
    ).assignable_issues

    issues.count
    # rubocop: enable CodeReuse/ServiceClass
  end

  def can_revert_on_current_merge_request?
    can_collaborate_with_project?(project) && cached_can_be_reverted?
  end

  def can_cherry_pick_on_current_merge_request?
    can_collaborate_with_project?(project) && can_be_cherry_picked?
  end

  def can_push_to_source_branch?
    return false unless source_branch_exists?

    !!::Gitlab::UserAccess
      .new(current_user, container: source_project)
      .can_push_to_branch?(source_branch)
  end

  delegator_override :can_remove_source_branch?
  def can_remove_source_branch?
    source_branch_exists? && merge_request.can_remove_source_branch?(current_user)
  end

  def can_read_pipeline?
    pipeline && can?(current_user, :read_pipeline, pipeline)
  end

  def mergeable_discussions_state
    merge_request.mergeable_discussions_state?
  end

  delegator_override :subscribed?
  def subscribed?
    merge_request.subscribed?(current_user, merge_request.target_project)
  end

  def source_branch_link
    if source_branch_exists?
      link_to(source_branch, source_branch_commits_path, class: 'ref-container gl-link')
    else
      content_tag(:span, source_branch, class: 'ref-name')
    end
  end

  def target_branch_link
    if target_branch_exists?
      link_to(target_branch, target_branch_commits_path, class: 'ref-container gl-link')
    else
      content_tag(:span, target_branch, class: 'ref-name')
    end
  end

  def api_approvals_path
    expose_path(api_v4_projects_merge_requests_approvals_path(id: project.id, merge_request_iid: merge_request.iid))
  end

  def api_approve_path
    expose_path(api_v4_projects_merge_requests_approve_path(id: project.id, merge_request_iid: merge_request.iid))
  end

  def api_unapprove_path
    expose_path(api_v4_projects_merge_requests_unapprove_path(id: project.id, merge_request_iid: merge_request.iid))
  end

  def approvals_widget_type
    APPROVALS_WIDGET_BASE_TYPE
  end

  def closing_issues
    strong_memoize(:closing_issues) do
      visible_closing_issues_for(current_user)
    end
  end

  def mentioned_issues
    strong_memoize(:mentioned_issues) do
      issues_mentioned_but_not_closing(current_user)
    end
  end

  delegator_override :pipeline_coverage_delta
  def pipeline_coverage_delta
    return unless merge_request.pipeline_coverage_delta.present?

    '%.2f' % merge_request.pipeline_coverage_delta
  end

  def jenkins_integration_active
    project.jenkins_integration_active?
  end

  private

  def cached_can_be_reverted?
    strong_memoize(:can_be_reverted) do
      can_be_reverted?(current_user)
    end
  end

  def conflicts
    # rubocop: disable CodeReuse/ServiceClass
    @conflicts ||= MergeRequests::Conflicts::ListService.new(merge_request)
    # rubocop: enable CodeReuse/ServiceClass
  end

  def pipeline
    @pipeline ||= diff_head_pipeline
  end

  def issues_sentence(project, issues)
    # Sorting based on the `#123` or `group/project#123` reference will sort
    # local issues numerically first.
    issue_refs = issues.map do |issue|
      issue.to_reference(project)
    end

    issue_refs.sort_by do |issue_ref|
      path_section = issue_ref.split('#')
      [path_section.first, path_section.last.to_i]
    end.to_sentence
  end

  def user_can_fork_project?
    can?(current_user, :fork_project, project)
  end

  # Avoid including ActionView::Helpers::UrlHelper
  def link_to(...)
    ApplicationController.helpers.link_to(...)
  end
end

MergeRequestPresenter.prepend_mod_with('MergeRequestPresenter')
