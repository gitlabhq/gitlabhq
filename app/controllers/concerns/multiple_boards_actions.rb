# frozen_string_literal: true

module MultipleBoardsActions
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  included do
    include BoardsActions

    before_action :redirect_to_recent_board, only: [:index]
    before_action :authenticate_user!, only: [:recent]
    before_action :authorize_create_board!, only: [:create]
    before_action :authorize_admin_board!, only: [:create, :update, :destroy]
  end

  def recent
    recent_visits = ::Boards::VisitsFinder.new(parent, current_user).latest(4)
    recent_boards = recent_visits.map(&:board)

    render json: serialize_as_json(recent_boards)
  end

  def create
    response = Boards::CreateService.new(parent, current_user, board_params).execute

    respond_to do |format|
      format.json do
        board = response.payload

        if response.success?
          extra_json = { board_path: board_path(board) }
          render json: serialize_as_json(board).merge(extra_json)
        else
          render json: board.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def update
    service = Boards::UpdateService.new(parent, current_user, board_params)

    respond_to do |format|
      format.json do
        if service.execute(board)
          extra_json = { board_path: board_path(board) }
          render json: serialize_as_json(board).merge(extra_json)
        else
          render json: board.errors, status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    service = Boards::DestroyService.new(parent, current_user)
    service.execute(board)

    respond_to do |format|
      format.json { head :ok }
      format.html { redirect_to boards_path, status: :found }
    end
  end

  private

  def redirect_to_recent_board
    return unless board_type == Board.to_type
    return if request.format.json? || !parent.multiple_issue_boards_available? || !latest_visited_board

    redirect_to board_path(latest_visited_board.board)
  end

  def latest_visited_board
    @latest_visited_board ||= Boards::VisitsFinder.new(parent, current_user).latest
  end

  def authorize_create_board!
    check_multiple_group_issue_boards_available! if group?
  end

  def authorize_admin_board!
    return render_404 unless can?(current_user, :admin_issue_board, parent)
  end

  def serializer
    BoardSerializer.new(current_user: current_user)
  end

  def serialize_as_json(resource)
    serializer.represent(resource, serializer: 'board', include_full_project_path: board.group_board?)
  end
end
