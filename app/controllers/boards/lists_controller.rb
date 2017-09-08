module Boards
  class ListsController < Boards::ApplicationController
    include BoardsResponses

    before_action :authorize_admin_list, only: [:create, :update, :destroy, :generate]
    before_action :authorize_read_list, only: [:index]
    skip_before_action :authenticate_user!, only: [:index]

    def index
      lists = Boards::Lists::ListService.new(board.parent, current_user).execute(board)

      render json: serialize_as_json(lists)
    end

    def create
      list = Boards::Lists::CreateService.new(board.parent, current_user, list_params).execute(board)

      if list.valid?
        render json: serialize_as_json(list)
      else
        render json: list.errors, status: :unprocessable_entity
      end
    end

    def update
      list = board.lists.movable.find(params[:id])
      service = Boards::Lists::MoveService.new(board_parent, current_user, move_params)

      if service.execute(list)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def destroy
      list = board.lists.destroyable.find(params[:id])
      service = Boards::Lists::DestroyService.new(board_parent, current_user)

      if service.execute(list)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    def generate
      service = Boards::Lists::GenerateService.new(board_parent, current_user)

      if service.execute(board)
        render json: serialize_as_json(board.lists.movable)
      else
        head :unprocessable_entity
      end
    end

    private

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
