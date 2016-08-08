class Projects::BoardIssuesController < Projects::ApplicationController
  respond_to :json

  before_action :authorize_read_issue!, only: [:index]
  before_action :authorize_update_issue!, only: [:update]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def index
    issues = Boards::Issues::ListService.new(project, current_user, filter_params).execute
    issues = issues.page(params[:page])

    render json: issues.as_json(
      only: [:iid, :title, :confidential],
      include: {
        assignee: { only: [:id, :name, :username], methods: [:avatar_url] },
        labels:   { only: [:id, :title, :color] }
      })
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

  def authorize_read_issue!
    return render_403 unless can?(current_user, :read_issue, project)
  end

  def authorize_update_issue!
    return render_403 unless can?(current_user, :update_issue, project)
  end

  def filter_params
    params.merge(id: params[:list_id])
  end

  def move_params
    params.require(:issue).permit(:from, :to).merge(id: params[:id])
  end

  def record_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
