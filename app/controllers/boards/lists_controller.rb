# frozen_string_literal: true

module Boards
  class ListsController < Boards::ApplicationController
    include BoardsResponses

    before_action :authorize_admin_list, only: [:create, :destroy, :generate]
    before_action :authorize_read_list, only: [:index]
    skip_before_action :authenticate_user!, only: [:index]

    def index
      lists = Boards::Lists::ListService.new(board.resource_parent, current_user).execute(board)

      List.preload_preferences_for_user(lists, current_user)

      render json: serialize_as_json(lists)
    end

    def create
      list = Boards::Lists::CreateService.new(board.resource_parent, current_user, create_list_params).execute(board)

      if list.valid?
        render json: serialize_as_json(list)
      else
        render json: list.errors, status: :unprocessable_entity
      end
    end

    def update
      list = board.lists.find(params[:id])
      service = Boards::Lists::UpdateService.new(board_parent, current_user, update_list_params)
      result = service.execute(list)

      if result[:status] == :success
        head :ok
      else
        head result[:http_status]
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
        lists = board.lists.movable.preload_associated_models

        List.preload_preferences_for_user(lists, current_user)

        render json: serialize_as_json(lists)
      else
        head :unprocessable_entity
      end
    end

    private

    def list_creation_attrs
      %i[label_id]
    end

    def list_update_attrs
      %i[collapsed position]
    end

    def create_list_params
      params.require(:list).permit(list_creation_attrs)
    end

    def update_list_params
      params.require(:list).permit(list_update_attrs)
    end

    def serialize_as_json(resource)
      resource.as_json(serialization_attrs)
    end

    def serialization_attrs
      {
        only: [:id, :list_type, :position],
        methods: [:title],
        label: true,
        collapsed: true,
        current_user: current_user
      }
    end
  end
end

Boards::ListsController.prepend_if_ee('EE::Boards::ListsController')
