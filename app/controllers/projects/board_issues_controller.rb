class Projects::BoardIssuesController < Projects::ApplicationController
  respond_to :json

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    issues = Boards::Issues::ListService.new(project, current_user, filter_params).execute
    issues = issues.page(params[:page])

    render json: issues.as_json(only: [:id, :title, :confidential], include: { labels: { only: [:id, :title, :color] } })
  end

  def update
    service = Boards::Issues::MoveService.new(project, current_user, move_params)

    if service.execute
      head :ok
    else
      head :unprocessable_entity
    end
  end

  private

  def filter_params
    params.permit(:list_id)
  end

  def move_params
    params.require(:issue).permit(:from, :to).merge(id: params[:id])
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
