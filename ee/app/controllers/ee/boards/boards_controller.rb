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
              extra_json = { board_path: board_path(board) }
              render json: serialize_as_json(board).merge(extra_json)
            else
              render json: board.errors, status: :unprocessable_entity
            end
          end
        end
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def update
        service = ::Boards::UpdateService.new(parent, current_user, board_params)

        service.execute(@board)

        respond_to do |format|
          format.json do
            if @board.valid?
              extra_json = { board_path: board_path(@board) }
              render json: serialize_as_json(@board).merge(extra_json)
            else
              render json: @board.errors, status: :unprocessable_entity
            end
          end
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def destroy
        service = ::Boards::DestroyService.new(parent, current_user)
        service.execute(@board) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        respond_to do |format|
          format.json { head :ok }
          format.html { redirect_to boards_path, status: 302 }
        end
      end

      private

      def authorize_admin_board!
        return render_404 unless can?(current_user, :admin_board, parent)
      end

      def board_params
        params.require(:board).permit(:name, :weight, :milestone_id, :assignee_id, label_ids: [])
      end

      def find_board
        @board = parent.boards.find(params[:id]) # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def parent
        @parent ||= @project || @group # rubocop:disable Gitlab/ModuleWithInstanceVariables
      end

      def boards_path
        if @group # rubocop:disable Gitlab/ModuleWithInstanceVariables
          group_boards_path(parent)
        else
          project_boards_path(parent)
        end
      end

      def board_path(board)
        if @group # rubocop:disable Gitlab/ModuleWithInstanceVariables
          group_board_path(parent, board)
        else
          project_board_path(parent, board)
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
