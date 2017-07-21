class Projects::BoardsController < Projects::ApplicationController
  prepend EE::Projects::BoardsController
  include IssuableCollections

  before_action :authorize_read_board!, only: [:index, :show]
  before_action :assign_endpoint_vars

  def index
    @boards = ::Boards::ListService.new(project, current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@boards)
      end
    end
  end

  def show
    @board = project.boards.find(params[:id])

    respond_to do |format|
      format.html
      format.json do
        render json: serialize_as_json(@board)
      end
    end
  end

  private

  def assign_endpoint_vars
    @boards_endpoint = project_boards_path(project)
    @issues_path = project_issues_path(project)
    @bulk_issues_path = bulk_update_project_issues_path(@project)
  end

  def authorize_read_board!
    return access_denied! unless can?(current_user, :read_board, project)
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end
end
