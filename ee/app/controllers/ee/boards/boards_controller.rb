# Shared actions between Groups::BoardsController and Projects::BoardsController
module EE
  module Boards
    module BoardsController
      include ::Gitlab::Utils::StrongMemoize
      extend ActiveSupport::Concern

      prepended do
        before_action :authorize_create_board!, only: [:create]
        before_action :authorize_admin_board!, only: [:create, :update, :destroy]
      end

      def create
        board = ::Boards::CreateService.new(parent, current_user, board_params).execute

        respond_to do |format|
          format.json do
            if board.valid?
              extra_json = { board_path: board_path(board) }
              render json: serialize_as_json(board).merge(extra_json)
            else
              render json: board.errors, status: :unprocessable_entity
            end
          end
        end
      end

      def update
        service = ::Boards::UpdateService.new(parent, current_user, board_params)

        service.execute(board)

        respond_to do |format|
          format.json do
            if board.valid?
              extra_json = { board_path: board_path(board) }
              render json: serialize_as_json(board).merge(extra_json)
            else
              render json: board.errors, status: :unprocessable_entity
            end
          end
        end
      end

      def destroy
        service = ::Boards::DestroyService.new(parent, current_user)
        service.execute(board)

        respond_to do |format|
          format.json { head :ok }
          format.html { redirect_to boards_path, status: 302 }
        end
      end

      private

      def board
        strong_memoize(:board) do
          parent.boards.find(params[:id])
        end
      end

      def authorize_create_board!
        if group?
          check_multiple_group_issue_boards_available!
        else
          check_multiple_project_issue_boards_available!
        end
      end

      def authorize_admin_board!
        return render_404 unless can?(current_user, :admin_board, parent)
      end

      def serialize_as_json(resource)
        resource.as_json(
          only: [:id, :name],
          include: {
            milestone: { only: [:id, :title] }
          }
        )
      end
    end
  end
end
