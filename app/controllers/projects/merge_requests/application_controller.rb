class Projects::MergeRequests::ApplicationController < Projects::ApplicationController
  prepend ::EE::Projects::MergeRequests::ApplicationController

  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :authorize_read_merge_request!
  before_action :ensure_ref_fetched

  private

  def merge_request
    @issuable = @merge_request ||= @project.merge_requests.find_by!(iid: params[:id])
  end

  # Make sure merge requests created before 8.0
  # have head file in refs/merge-requests/
  def ensure_ref_fetched
    @merge_request.ensure_ref_fetched
  end

  def merge_request_params
    params.require(:merge_request).permit(merge_request_params_attributes)
  end

  def merge_request_params_attributes
    [
      :assignee_id,
      :description,
      :force_remove_source_branch,
      :lock_version,
      :milestone_id,
      :source_branch,
      :source_project_id,
      :state_event,
      :target_branch,
      :target_project_id,
      :task_num,
      :title,

      label_ids: []
    ]
  end

  def set_pipeline_variables
    @pipelines = @merge_request.all_pipelines
    @pipeline = @merge_request.head_pipeline
    @statuses_count = @pipeline.present? ? @pipeline.statuses.relevant.count : 0
  end
end
