class Projects::BoardsController < Projects::ApplicationController
  include IssuableCollections
  
  respond_to :html

  before_action :authorize_read_board!, only: [:show]

  def show
    ::Boards::CreateService.new(project, current_user).execute
  end

  private

  def authorize_read_board!
    return access_denied! unless can?(current_user, :read_board, project)
  end
end
