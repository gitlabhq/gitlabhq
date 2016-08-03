class Projects::BoardsController < Projects::ApplicationController
  def show
    board = Boards::CreateService.new(project, current_user).execute

    respond_to do |format|
      format.html
      format.json { render json: board.lists.as_json(only: [:id, :list_type, :position], methods: [:title], include: { label: { only: [:id, :title, :color] } }) }
    end
  end
end
