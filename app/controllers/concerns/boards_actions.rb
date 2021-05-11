# frozen_string_literal: true

module BoardsActions
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  included do
    include BoardsResponses

    before_action :authorize_read_board!, only: [:index, :show]
    before_action :boards, only: :index
    before_action :board, only: :show
    before_action :push_licensed_features, only: [:index, :show]
  end

  def index
    respond_with_boards
  end

  def show
    # Add / update the board in the recent visits table
    board_visit_service.new(parent, current_user).execute(board) if request.format.html?

    respond_with_board
  end

  private

  # Noop on FOSS
  def push_licensed_features
  end

  def boards
    strong_memoize(:boards) do
      existing_boards = boards_finder.execute
      if existing_boards.any?
        existing_boards
      else
        # if no board exists, create one
        [board_create_service.execute.payload]
      end
    end
  end

  def board
    strong_memoize(:board) do
      board_finder.execute.first
    end
  end

  def board_type
    board_klass.to_type
  end

  def board_visit_service
    Boards::Visits::CreateService
  end

  def serializer
    BoardSerializer.new(current_user: current_user)
  end

  def serialize_as_json(resource)
    serializer.represent(resource, serializer: 'board', include_full_project_path: board.group_board?)
  end
end

BoardsActions.prepend_mod_with('BoardsActions')
