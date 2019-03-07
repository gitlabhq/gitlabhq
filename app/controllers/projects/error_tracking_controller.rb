# frozen_string_literal: true

class Projects::ErrorTrackingController < Projects::ApplicationController
  before_action :authorize_read_sentry_issue!

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

  def list_projects
    respond_to do |format|
      format.json do
        render_project_list_json
      end
    end
  end

  private

  def render_index_json
    service = ErrorTracking::ListIssuesService.new(project, current_user)
    result = service.execute

    unless result[:status] == :success
      return render json: { message: result[:message] },
                    status: result[:http_status] || :bad_request
    end

    render json: {
      errors: serialize_errors(result[:issues]),
      external_url: service.external_url
    }
  end

  def render_project_list_json
    service = ErrorTracking::ListProjectsService.new(
      project,
      current_user,
      list_projects_params
    )
    result = service.execute

    if result[:status] == :success
      render json: {
        projects: serialize_projects(result[:projects])
      }
    else
      return render(
        status: result[:http_status] || :bad_request,
        json: {
          message: result[:message]
        }
      )
    end
  end

  def list_projects_params
    params.require(:error_tracking_setting).permit([:api_host, :token])
  end

  def set_polling_interval
    Gitlab::PollingInterval.set_header(response, interval: POLLING_INTERVAL)
  end

  def serialize_errors(errors)
    ErrorTracking::ErrorSerializer
      .new(project: project, user: current_user)
      .represent(errors)
  end

  def serialize_projects(projects)
    ErrorTracking::ProjectSerializer
      .new(project: project, user: current_user)
      .represent(projects)
  end
end
