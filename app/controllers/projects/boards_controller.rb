class Projects::BoardsController < Projects::ApplicationController
  prepend EE::Boards::BoardsController
  include BoardsResponses
  include IssuableCollections

  before_action :check_issues_available!
  before_action :authorize_read_board!, only: [:index, :show]
  before_action :assign_endpoint_vars

  def index
    @boards = Boards::ListService.new(project, current_user).execute

    respond_with_boards
  end

  def show
    @board = project.boards.find(params[:id])

    respond_with_board
  end

  private

  def assign_endpoint_vars
    @boards_endpoint = project_boards_path(project)
    @bulk_issues_path = bulk_update_project_issues_path(project)
    @namespace_path = project.namespace.full_path
    @labels_endpoint = project_labels_path(project)
  end

  def authorize_read_board!
    return access_denied! unless can?(current_user, :read_board, project)
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end
end
