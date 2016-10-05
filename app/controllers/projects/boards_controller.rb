class Projects::BoardsController < Projects::ApplicationController
  include IssuableCollections

  before_action :authorize_read_board!, only: [:index, :show]

  def index
    @boards = ::Boards::ListService.new(project, current_user).execute

    respond_to do |format|
      format.html
      format.json do
        render json: @boards.as_json(only: [:id, :name])
      end
    end
  end

  def show
    ::Boards::CreateService.new(project, current_user).execute
  end

  private

  def authorize_read_board!
    return access_denied! unless can?(current_user, :read_board, project)
  end
end
