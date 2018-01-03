module Boards
  class ApplicationController < ::ApplicationController
    respond_to :json

    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

    private

    def board
      @board ||= Board.find(params[:board_id])
    end

    def board_parent
      @board_parent ||= board.parent
    end

    def record_not_found(exception)
      render json: { error: exception.message }, status: :not_found
    end
  end
end
