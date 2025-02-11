# frozen_string_literal: true

class Projects::MergeRequests::ApplicationController < Projects::ApplicationController
  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :authorize_read_merge_request!

  feature_category :code_review_workflow

  before_action do
    push_force_frontend_feature_flag(:glql_integration, project&.glql_integration_feature_flag_enabled?)
    push_force_frontend_feature_flag(:continue_indented_text, project&.continue_indented_text_feature_flag_enabled?)
  end

  private

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
        merge_request_includes(@project.merge_requests).find_by_iid!(params[:id])

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
        update_task: [:index, :checked, :line_number, :line_source] }
    ]
  end

  def set_pipeline_variables
    @pipelines = Ci::PipelinesForMergeRequestFinder
      .new(@merge_request, current_user)
      .execute
  end

  def close_merge_request_if_no_source_project
    return if @merge_request.source_project
    return unless @merge_request.open?

    @merge_request.close
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def commit
    commit_id = params[:commit_id].presence
    return unless commit_id

    return unless @merge_request.all_commits.exists?(sha: commit_id) ||
      @merge_request.recent_context_commits.map(&:id).include?(commit_id)

    @commit ||= @project.commit(commit_id)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def build_merge_request
    params[:merge_request] ||= ActionController::Parameters.new(source_project: @project)
    new_params = merge_request_params.merge(diff_options: diff_options)

    # Gitaly N+1 issue: https://gitlab.com/gitlab-org/gitlab-foss/issues/58096
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      @merge_request = ::MergeRequests::BuildService
        .new(project: project, current_user: current_user, params: new_params)
        .execute
    end
  end
end

Projects::MergeRequests::ApplicationController.prepend_mod_with('Projects::MergeRequests::ApplicationController')
