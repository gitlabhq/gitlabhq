# frozen_string_literal: true

module MergeRequestsHelper
  include Gitlab::Utils::StrongMemoize

  def new_mr_path_from_push_event(event)
    target_project = event.project.default_merge_request_target
    project_new_merge_request_path(
      event.project,
      new_mr_from_push_event(event, target_project)
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
    classes = ["merge-request"]
    classes << "closed" if mr.closed?
    classes << "merged" if mr.merged?
    classes.join(' ')
  end

  def merge_path_description(merge_request, separator)
    if merge_request.for_fork?
      "Project:Branches: #{@merge_request.source_project_path}:#{@merge_request.source_branch} #{separator} #{@merge_request.target_project.full_path}:#{@merge_request.target_branch}"
    else
      "Branches: #{@merge_request.source_branch} #{separator} #{@merge_request.target_branch}"
    end
  end

  def mr_change_branches_path(merge_request)
    project_new_merge_request_path(
      @project,
      merge_request: {
        source_project_id: merge_request.source_project_id,
        target_project_id: merge_request.target_project_id,
        source_branch: merge_request.source_branch,
        target_branch: merge_request.target_branch
      },
      change_branches: true
    )
  end

  def format_mr_branch_names(merge_request)
    source_path = merge_request.source_project_path
    target_path = merge_request.target_project_path
    source_branch = merge_request.source_branch
    target_branch = merge_request.target_branch

    if source_path == target_path
      [source_branch, target_branch]
    else
      ["#{source_path}:#{source_branch}", "#{target_path}:#{target_branch}"]
    end
  end

  def target_projects(project)
    MergeRequestTargetProjectFinder.new(current_user: current_user, source_project: project)
      .execute(include_routes: true)
  end

  def merge_request_button_visibility(merge_request, closed)
    return 'hidden' if merge_request_button_hidden?(merge_request, closed)
  end

  def merge_request_button_hidden?(merge_request, closed)
    merge_request.closed? == closed || (merge_request.merged? == closed && !merge_request.closed?) || merge_request.closed_or_merged_without_fork?
  end

  def merge_request_version_path(project, merge_request, merge_request_diff, start_sha = nil)
    diffs_project_merge_request_path(project, merge_request, diff_id: merge_request_diff.id, start_sha: start_sha)
  end

  def merge_params(merge_request)
    {
      auto_merge_strategy: AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS,
      should_remove_source_branch: true,
      sha: merge_request.diff_head_sha,
      squash: merge_request.squash_on_merge?
    }
  end

  def tab_link_for(merge_request, tab, options = {}, &block)
    data_attrs = {
      action: tab.to_s,
      target: "##{tab}",
      toggle: options.fetch(:force_link, false) ? '' : 'tabvue'
    }

    url = case tab
          when :show
            data_attrs[:target] = '#notes'
            method(:project_merge_request_path)
          when :commits
            method(:commits_project_merge_request_path)
          when :pipelines
            method(:pipelines_project_merge_request_path)
          when :diffs
            method(:diffs_project_merge_request_path)
          else
            raise "Cannot create tab #{tab}."
          end

    link_to(url[merge_request.project, merge_request], data: data_attrs, &block)
  end

  def allow_collaboration_unavailable_reason(merge_request)
    return if merge_request.can_allow_collaboration?(current_user)

    minimum_visibility = [merge_request.target_project.visibility_level,
                          merge_request.source_project.visibility_level].min

    if minimum_visibility < Gitlab::VisibilityLevel::INTERNAL
      _('Not available for private projects')
    elsif ProtectedBranch.protected?(merge_request.source_project, merge_request.source_branch)
      _('Not available for protected branches')
    end
  end

  def merge_request_source_project_for_project(project = @project)
    unless can?(current_user, :create_merge_request_in, project)
      return
    end

    if can?(current_user, :create_merge_request_from, project)
      project
    else
      current_user.fork_of(project)
    end
  end

  def toggle_draft_merge_request_path(issuable)
    wip_event = issuable.work_in_progress? ? 'unwip' : 'wip'

    issuable_path(issuable, { merge_request: { wip_event: wip_event } })
  end

  def user_merge_requests_counts
    @user_merge_requests_counts ||= begin
      assigned_count = assigned_issuables_count(:merge_requests)
      review_requested_count = review_requested_merge_requests_count
      total_count = assigned_count + review_requested_count

      {
        assigned: assigned_count,
        review_requested: review_requested_count,
        total: total_count
      }
    end
  end

  def reviewers_label(merge_request, include_value: true)
    reviewers = merge_request.reviewers

    if include_value
      sanitized_list = sanitize_name(reviewers.map(&:name).to_sentence)
      ns_('NotificationEmail|Reviewer: %{users}', 'NotificationEmail|Reviewers: %{users}', reviewers.count) % { users: sanitized_list }
    else
      ns_('NotificationEmail|Reviewer', 'NotificationEmail|Reviewers', reviewers.count)
    end
  end

  def diffs_tab_pane_data(project, merge_request, params)
    {
      "is-locked": merge_request.discussion_locked?,
      endpoint: diffs_project_merge_request_path(project, merge_request, 'json', params),
      endpoint_metadata: @endpoint_metadata_url,
      endpoint_batch: diffs_batch_project_json_merge_request_path(project, merge_request, 'json', params),
      endpoint_coverage: @coverage_path,
      help_page_path: help_page_path('user/discussions/index.md', anchor: 'suggest-changes'),
      current_user_data: @current_user_data,
      update_current_user_path: @update_current_user_path,
      project_path: project_path(merge_request.project),
      changes_empty_state_illustration: image_path('illustrations/merge_request_changes_empty.svg'),
      is_fluid_layout: fluid_layout.to_s,
      dismiss_endpoint: user_callouts_path,
      show_suggest_popover: show_suggest_popover?.to_s,
      show_whitespace_default: @show_whitespace_default.to_s,
      file_by_file_default: @file_by_file_default.to_s,
      default_suggestion_commit_message: default_suggestion_commit_message
    }
  end

  def award_emoji_merge_request_api_path(merge_request)
    if Feature.enabled?(:improved_emoji_picker, merge_request.project, default_enabled: :yaml)
      api_v4_projects_merge_requests_award_emoji_path(id: merge_request.project.id, merge_request_iid: merge_request.iid)
    end
  end

  private

  def review_requested_merge_requests_count
    current_user.review_requested_open_merge_requests_count
  end

  def default_suggestion_commit_message
    @project.suggestion_commit_message.presence || Gitlab::Suggestions::CommitMessage::DEFAULT_SUGGESTION_COMMIT_MESSAGE
  end
end

MergeRequestsHelper.prepend_mod_with('MergeRequestsHelper')
