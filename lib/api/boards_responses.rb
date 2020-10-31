# frozen_string_literal: true

module API
  module BoardsResponses
    extend ActiveSupport::Concern

    included do
      helpers do
        def board
          board_parent.boards.find(params[:board_id])
        end

        def create_board
          forbidden! unless board_parent.multiple_issue_boards_available?

          response =
            ::Boards::CreateService.new(board_parent, current_user, { name: params[:name] }).execute

          present response.payload, with: Entities::Board
        end

        def update_board
          service = ::Boards::UpdateService.new(board_parent, current_user, declared_params(include_missing: false))
          service.execute(board)

          if board.valid?
            present board, with: Entities::Board
          else
            bad_request!("Failed to save board #{board.errors.messages}")
          end
        end

        def delete_board
          forbidden! unless board_parent.multiple_issue_boards_available?

          destroy_conditionally!(board) do |board|
            service = ::Boards::DestroyService.new(board_parent, current_user)
            service.execute(board)
          end
        end

        def board_lists
          board.destroyable_lists
        end

        def create_list
          create_list_service =
            ::Boards::Lists::CreateService.new(board_parent, current_user, create_list_params)

          list = create_list_service.execute(board)

          if list.valid?
            present list, with: Entities::List
          else
            render_validation_error!(list)
          end
        end

        def create_list_params
          params.slice(:label_id)
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
            if service.execute(list).error?
              render_api_error!({ error: 'List could not be deleted!' }, 400)
            end
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def authorize_list_type_resource!
          unless available_labels_for(board_parent).exists?(params[:label_id])
            render_api_error!({ error: 'Label not found!' }, 400)
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        params :list_creation_params do
          requires :label_id, type: Integer, desc: 'The ID of an existing label'
        end

        params :update_params do
          # Configurable issue boards are not available in CE/EE Core.
          # https://docs.gitlab.com/ee/user/project/issue_board.html#configurable-issue-boards
          optional :name, type: String, desc: 'The board name'
        end
      end
    end
  end
end
