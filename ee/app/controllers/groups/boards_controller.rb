class Groups::BoardsController < Groups::ApplicationController
  prepend EE::Boards::BoardsController
  prepend EE::BoardsResponses
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
    @boards_endpoint = group_boards_url(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_url(group)
  end
end
