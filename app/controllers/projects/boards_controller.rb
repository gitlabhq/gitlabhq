class Projects::BoardsController < Projects::ApplicationController
  before_action :authorize_read_board!, only: [:show]

  def show
    board = Boards::CreateService.new(project, current_user).execute

    respond_to do |format|
      format.html
      format.json { render json: board.lists.as_json(only: [:id, :list_type, :position], methods: [:title], include: { label: { only: [:id, :title, :description, :color, :priority] } }) }
    end
  end

  private

  def authorize_read_board!
    unless can?(current_user, :read_board, project)
      respond_to do |format|
        format.html { return access_denied! }
        format.json { return render_403 }
      end
    end
  end
end
