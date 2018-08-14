class Groups::BoardsController < Groups::ApplicationController
  include BoardsResponses

  before_action :assign_endpoint_vars
  before_action :boards, only: :index

  def index
    respond_with_boards
  end

  def show
    @board = boards.find(params[:id])

    respond_with_board
  end

  private

  def boards
    @boards ||= Boards::ListService.new(group, current_user).execute
  end

  def assign_endpoint_vars
    @boards_endpoint = group_boards_url(group)
    @namespace_path = group.to_param
    @labels_endpoint = group_labels_url(group)
  end

  def serialize_as_json(resource)
    resource.as_json(only: [:id])
  end
end
