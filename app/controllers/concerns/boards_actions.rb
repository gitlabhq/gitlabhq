# frozen_string_literal: true

module BoardsActions
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  included do
    include BoardsResponses

    before_action :redirect_to_recent_board, only: :index
    before_action :boards, only: :index
    before_action :board, only: :show
  end

  def index
    respond_with_boards
  end

  def show
    # Add / update the board in the recent visits table
    Boards::Visits::CreateService.new(parent, current_user).execute(board) if request.format.html?

    respond_with_board
  end

  private

  def redirect_to_recent_board
    return if request.format.json?

    if recently_visited = Boards::Visits::LatestService.new(board_parent, current_user).execute
      board_path = case board_parent
                   when Project
                     namespace_project_board_path(id: recently_visited.board_id)
                   when Group
                     group_board_path(id: recently_visited.board_id)
                   end

      redirect_to board_path
    end
  end

  def boards
    strong_memoize(:boards) do
      Boards::ListService.new(parent, current_user).execute
    end
  end

  def board
    strong_memoize(:board) do
      boards.find(params[:id])
    end
  end
end
