module EE
  module Boards
    module BoardsController
      extend ActiveSupport::Concern
      prepended do
        before_action :check_multiple_issue_boards_available!, only: [:create]
        before_action :authorize_admin_board!, only: [:create, :update, :destroy]
        before_action :find_board, only: [:update, :destroy]
      end

      def create
        board = ::Boards::CreateService.new(parent, current_user, board_params).execute

        respond_to do |format|
          format.json do
            if board.valid?
              render json: serialize_as_json(board)
            else
              render json: board.errors, status: :unprocessable_entity
            end
          end
        end
      end

      def update
        service = ::Boards::UpdateService.new(parent, current_user, board_params)

        service.execute(@board)

        respond_to do |format|
          format.json do
            if @board.valid?
              render json: serialize_as_json(@board)
            else
              render json: @board.errors, status: :unprocessable_entity
            end
          end
        end
      end

      def destroy
        service = ::Boards::DestroyService.new(parent, current_user)
        service.execute(@board)

        respond_to do |format|
          format.html { redirect_to boards_path, status: 302 }
        end
      end

      private

      def authorize_admin_board!
        return render_404 unless can?(current_user, :admin_board, parent)
      end

      def board_params
        params.require(:board).permit(:name, :milestone_id)
      end

      def find_board
        @board = parent.boards.find(params[:id])
      end

      def parent
        @parent ||= @project || @group
      end

      def boards_path
        if parent.is_a?(Group)
          group_boards_path(parent)
        else
          project_boards_path(parent)
        end
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
