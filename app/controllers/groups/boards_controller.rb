class Groups::BoardsController < Groups::ApplicationController
  prepend EE::Boards::BoardsController
  include BoardsResponses

  before_action :check_group_issue_boards_available!
  before_action :assign_endpoint_vars

  def index
    @boards = Boards::ListService.new(group, current_user).execute

    respond_with_boards
  end

  def show
    @board = group.boards.find(params[:id])

    respond_with_board
  end

  def assign_endpoint_vars
    @boards_endpoint = group_boards_path(group)
    @namespace_path = group.path
    @labels_endpoint = group_labels_path(group)
  end
end
