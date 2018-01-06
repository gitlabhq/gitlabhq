module API
  module BoardsResponses
    extend ActiveSupport::Concern

    included do
      helpers do
        def board
          board_parent.boards.find(params[:board_id])
        end

        def board_lists
          board.lists.destroyable
        end

        def create_list
          create_list_service =
            ::Boards::Lists::CreateService.new(board_parent, current_user, { label_id: params[:label_id] })

          list = create_list_service.execute(board)

          if list.valid?
            present list, with: Entities::List
          else
            render_validation_error!(list)
          end
        end

        def move_list(list)
          move_list_service =
            ::Boards::Lists::MoveService.new(board_parent, current_user, { position: params[:position].to_i })

          if move_list_service.execute(list)
            present list, with: Entities::List
          else
            render_api_error!({ error: "List could not be moved!" }, 400)
          end
        end

        def destroy_list(list)
          destroy_conditionally!(list) do |list|
            service = ::Boards::Lists::DestroyService.new(board_parent, current_user)
            unless service.execute(list)
              render_api_error!({ error: 'List could not be deleted!' }, 400)
            end
          end
        end
      end
    end
  end
end
