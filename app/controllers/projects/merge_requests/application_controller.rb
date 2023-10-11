# frozen_string_literal: true

class Projects::MergeRequests::ApplicationController < Projects::ApplicationController
  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :authorize_read_merge_request!

  feature_category :code_review_workflow

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
      label_ids: [],
      assignee_ids: [],
      reviewer_ids: [],
      update_task: [:index, :checked, :line_number, :line_source]
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
end

Projects::MergeRequests::ApplicationController.prepend_mod_with('Projects::MergeRequests::ApplicationController')
