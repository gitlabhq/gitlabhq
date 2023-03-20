# frozen_string_literal: true

class Projects::ErrorTrackingController < Projects::ErrorTracking::BaseController
  respond_to :json

  before_action :authorize_read_sentry_issue!
  before_action :authorize_update_sentry_issue!, only: %i[update]
  before_action :set_issue_id, only: :details

  before_action only: [:index] do
    push_frontend_feature_flag(:integrated_error_tracking, project)
  end

  def index
    respond_to do |format|
      format.html
      format.json do
        set_polling_interval
        render_index_json
      end
    end
  end

  def details
    respond_to do |format|
      format.html
      format.json do
        set_polling_interval
        render_issue_detail_json
      end
    end
  end

  def update
    service = ::ErrorTracking::IssueUpdateService.new(project, current_user, issue_update_params)
    result = service.execute

    return if render_errors(result)

    render json: {
      result: result
    }
  end

  private

  def render_index_json
    service = ::ErrorTracking::ListIssuesService.new(
      project,
      current_user,
      list_issues_params
    )
    result = service.execute

    return if render_errors(result)

    render json: {
      errors: serialize_errors(result[:issues]),
      pagination: result[:pagination],
      external_url: service.external_url
    }
  end

  def render_issue_detail_json
    service = ::ErrorTracking::IssueDetailsService.new(project, current_user, issue_details_params)
    result = service.execute

    return if render_errors(result)

    render json: {
      error: serialize_detailed_error(result[:issue])
    }
  end

  def render_errors(result)
    unless result[:status] == :success
      render json: { message: result[:message] }, status: result[:http_status] || :bad_request
    end
  end

  def list_issues_params
    params.permit(:search_term, :sort, :cursor, :issue_status).merge(tracking_event: :error_tracking_view_list)
  end

  def issue_update_params
    params.permit(:issue_id, :status)
  end

  def issue_details_params
    params.permit(:issue_id).merge(tracking_event: :error_tracking_view_details)
  end

  def set_issue_id
    @issue_id = issue_details_params[:issue_id]
  end

  def serialize_errors(errors)
    ::ErrorTracking::ErrorSerializer
      .new(project: project, user: current_user)
      .represent(errors)
  end

  def serialize_detailed_error(error)
    ::ErrorTracking::DetailedErrorSerializer
      .new(project: project, user: current_user)
      .represent(error)
  end
end
