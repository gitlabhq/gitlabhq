module EE
  module Projects
    module BoardsController
      extend ActiveSupport::Concern
      prepended do
        before_action :check_multiple_issue_boards_available!, only: [:create]
        before_action :authorize_admin_board!, only: [:create, :update, :destroy]
        before_action :find_board, only: [:update, :destroy]
      end

      def create
        board = ::Boards::CreateService.new(project, current_user, board_params).execute

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
        service = ::Boards::UpdateService.new(project, current_user, board_params)

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
        service = ::Boards::DestroyService.new(project, current_user)
        service.execute(@board)

        respond_to do |format|
          format.html { redirect_to project_boards_path(@project), status: 302 }
        end
      end

      private

      def authorize_admin_board!
        return render_404 unless can?(current_user, :admin_board, project)
      end

      def board_params
        params.require(:board).permit(:name, :milestone_id)
      end

      def find_board
        @board = project.boards.find(params[:id])
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
