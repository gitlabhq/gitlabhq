class Projects::BoardsController < Projects::ApplicationController
  def show
    Boards::CreateService.new(project).execute

    respond_to do |format|
      format.html
    end
  end
end
