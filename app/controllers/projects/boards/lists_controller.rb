module Projects
  module Boards
    class ListsController < Boards::ApplicationController
      before_action :authorize_admin_list!, only: [:create, :update, :destroy, :generate]
      before_action :authorize_read_list!, only: [:index]

      def index
        render json: serialize_as_json(board.lists)
      end

      def create
        list = ::Boards::Lists::CreateService.new(project, current_user, list_params).execute(board)

        if list.valid?
          render json: serialize_as_json(list)
        else
          render json: list.errors, status: :unprocessable_entity
        end
      end

      def update
        list = board.lists.movable.find(params[:id])
        service = ::Boards::Lists::MoveService.new(project, current_user, move_params)

        if service.execute(list)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      def destroy
        list = board.lists.destroyable.find(params[:id])
        service = ::Boards::Lists::DestroyService.new(project, current_user)

        if service.execute(list)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      def generate
        service = ::Boards::Lists::GenerateService.new(project, current_user)

        if service.execute(board)
          render json: serialize_as_json(board.lists.movable)
        else
          head :unprocessable_entity
        end
      end

      private

      def authorize_admin_list!
        return render_403 unless can?(current_user, :admin_list, project)
      end

      def authorize_read_list!
        return render_403 unless can?(current_user, :read_list, project)
      end

      def board
        @board ||= project.boards.find(params[:board_id])
      end

      def list_params
        params.require(:list).permit(:label_id)
      end

      def move_params
        params.require(:list).permit(:position)
      end

      def serialize_as_json(resource)
        resource.as_json(
          only: [:id, :list_type, :position],
          methods: [:title],
          label: true
        )
      end
    end
  end
end
