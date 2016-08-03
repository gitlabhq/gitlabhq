class Projects::BoardIssuesController < Projects::ApplicationController
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    issues = Boards::Issues::ListService.new(project, current_user, filter_params).execute
    issues = issues.page(params[:page])

    render json: issues.as_json(only: [:id, :title, :confidential], include: { labels: { only: [:id, :title, :color] } })
  end

  private

  def filter_params
    params.permit(:list_id)
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
