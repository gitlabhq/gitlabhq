module Projects
  module Boards
    class ListsController < Boards::ApplicationController
      before_action :authorize_admin_list!, only: [:create, :update, :destroy, :generate]
      before_action :authorize_read_list!, only: [:index]

      def index
        render json: serialize_as_json(project.board.lists)
      end

      def create
        list = ::Boards::Lists::CreateService.new(project, current_user, list_params).execute

        if list.valid?
          render json: serialize_as_json(list)
        else
          render json: list.errors, status: :unprocessable_entity
        end
      end

      def update
        list = project.board.lists.find(params[:id])
        service = ::Boards::Lists::MoveService.new(project, current_user, move_params)

        if service.execute(list)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      def destroy
        list = project.board.lists.destroyable.find(params[:id])
        service = ::Boards::Lists::DestroyService.new(project, current_user, params)

        if service.execute(list)
          head :ok
        else
          head :unprocessable_entity
        end
      end

      def generate
        service = ::Boards::Lists::GenerateService.new(project, current_user)

        if service.execute
          render json: serialize_as_json(project.board.lists.label)
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
          include: {
            label: { only: [:id, :title, :description, :color, :priority] }
          })
      end
    end
  end
end
