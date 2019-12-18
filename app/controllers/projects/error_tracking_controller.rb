# frozen_string_literal: true

class Projects::ErrorTrackingController < Projects::ApplicationController
  before_action :authorize_read_sentry_issue!
  before_action :set_issue_id, only: [:details, :stack_trace]

  POLLING_INTERVAL = 10_000

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
        render_issue_detail_json
      end
    end
  end

  def stack_trace
    respond_to do |format|
      format.json do
        render_issue_stack_trace_json
      end
    end
  end

  private

  def render_index_json
    service = ErrorTracking::ListIssuesService.new(
      project,
      current_user,
      list_issues_params
    )
    result = service.execute

    return if handle_errors(result)

    render json: {
      errors: serialize_errors(result[:issues]),
      pagination: result[:pagination],
      external_url: service.external_url
    }
  end

  def render_issue_detail_json
    service = ErrorTracking::IssueDetailsService.new(project, current_user, issue_details_params)
    result = service.execute

    return if handle_errors(result)

    render json: {
      error: serialize_detailed_error(result[:issue])
    }
  end

  def render_issue_stack_trace_json
    service = ErrorTracking::IssueLatestEventService.new(project, current_user, issue_details_params)
    result = service.execute

    return if handle_errors(result)

    result_with_syntax_highlight = Gitlab::ErrorTracking::StackTraceHighlightDecorator.decorate(result[:latest_event])

    render json: {
      error: serialize_error_event(result_with_syntax_highlight)
    }
  end

  def handle_errors(result)
    unless result[:status] == :success
      render json: { message: result[:message] },
             status: result[:http_status] || :bad_request
    end
  end

  def list_issues_params
    params.permit(:search_term, :sort, :cursor)
  end

  def issue_details_params
    params.permit(:issue_id)
  end

  def set_issue_id
    @issue_id = issue_details_params[:issue_id]
  end

  def set_polling_interval
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
  end

  def serialize_errors(errors)
    ErrorTracking::ErrorSerializer
      .new(project: project, user: current_user)
      .represent(errors)
  end

  def serialize_detailed_error(error)
    ErrorTracking::DetailedErrorSerializer
      .new(project: project, user: current_user)
      .represent(error)
  end

  def serialize_error_event(event)
    ErrorTracking::ErrorEventSerializer
      .new(project: project, user: current_user)
      .represent(event)
  end
end
