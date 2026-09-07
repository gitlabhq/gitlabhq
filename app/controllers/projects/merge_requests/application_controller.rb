# frozen_string_literal: true

class Projects::MergeRequests::ApplicationController < Projects::ApplicationController
  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :authorize_read_merge_request!

  feature_category :code_review_workflow

  helper_method :rapid_diffs_presenter

  before_action do
    push_force_frontend_feature_flag(:glql_load_on_click, !!project&.glql_load_on_click_feature_flag_enabled?)
  end

  private

  PIPELINE_DISPLAY_LIMIT = 100

  def id_param
    params.permit(:id)[:id]
  end

  def commit_id_param
    params.permit(:commit_id)[:commit_id]
  end

  def rapid_diffs_presenter
    @rapid_diffs_presenter ||= ::RapidDiffs::MergeRequestPresenter.new(
      ::MergeRequests::VersionedMergeRequest.from_diff_options(@merge_request, rapid_diff_options),
      diff_view: diff_view,
      diff_options: rapid_diff_options,
      current_user: current_user,
      request_params: rapid_diff_params,
      conflicts: conflicts_with_types
    )
  end

  # Every key RapidDiffs::MergeRequestPresenter and its BasePresenter read.
  def rapid_diff_params
    @rapid_diff_params ||= params.permit(
      :diff_id, :start_sha, :commit_id, :only_context_commits, :old_path, :new_path, :file_path, :line
    )
  end

  def rapid_diff_options
    {
      diff_id: rapid_diff_params[:diff_id],
      start_sha: rapid_diff_params[:start_sha],
      commit_id: rapid_diff_params[:commit_id],
      only_context_commits: rapid_diff_params[:only_context_commits]
    }.compact.merge(diff_options)
  end

  # Normally the methods with `check_(\w+)_available!` pattern are
  # handled by the `method_missing` defined in `ProjectsController::ApplicationController`
  # but that logic does not take the member roles into account, therefore, we handle this
  # case here manually.
  def check_merge_requests_available!
    render_404 if project_policy.merge_requests_disabled?
  end

  def project_policy
    ProjectPolicy.new(current_user, project)
  end

  def merge_request
    @issuable =
      @merge_request ||=
        merge_request_includes(@project.merge_requests).find_by_iid!(id_param)

    return render_404 unless can?(current_user, :read_merge_request, @issuable)

    @issuable
  end

  def merge_request_includes(association)
    association.includes(preloadable_mr_relations) # rubocop:disable CodeReuse/ActiveRecord
  end

  def preloadable_mr_relations
    [:metrics, { assignees: :status }, { author: :status }]
  end

  def merge_request_params
    params.require(:merge_request).permit(merge_request_params_attributes)
  end

  def merge_request_params_attributes
    [
      :allow_collaboration,
      :description,
      :force_remove_source_branch,
      :lock_version,
      :milestone_id,
      :source_branch,
      :source_project_id,
      :state_event,
      :wip_event,
      :squash,
      :target_branch,
      :target_project_id,
      :task_num,
      :title,
      :discussion_locked,
      :issue_iid,
      :merge_after,
      { label_ids: [],
        assignee_ids: [],
        reviewer_ids: [],
        update_task: [:checked, :line_source, :line_sourcepos] }
    ]
  end

  def set_pipeline_variables
    @pipeline_display_limit = PIPELINE_DISPLAY_LIMIT
    @pipelines = Ci::PipelinesForMergeRequestFinder
      .new(@merge_request, current_user)
      .execute
  end

  def close_merge_request_if_no_source_project
    return if @merge_request.source_project
    return unless @merge_request.open?

    @merge_request.close
  end

  def commit
    @commit ||= ::Gitlab::MergeRequests::CommitResolver.new(@merge_request, commit_id_param)
      .resolve
  end

  def build_merge_request
    new_params = build_merge_request_params.merge(diff_options: diff_options)

    # Gitaly N+1 issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/58096
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      @merge_request = ::MergeRequests::BuildService
        .new(project: project, current_user: current_user, params: new_params)
        .execute
    end
  end

  # Delegates so EE's `merge_request_params` override still clamps `approvals_before_merge`.
  # `new` and the branch_from/branch_to partials are reachable with no `merge_request` key.
  def build_merge_request_params
    merge_request_params
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new.permit!
  end
end

Projects::MergeRequests::ApplicationController.prepend_mod_with('Projects::MergeRequests::ApplicationController')
