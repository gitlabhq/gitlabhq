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
            ::Boards::Lists::CreateService.new(board_parent, current_user, declared_params.compact.with_indifferent_access)

          response = create_list_service.execute(board)

          if response.success?
            present response.payload[:list], with: Entities::List
          else
            render_api_error!({ error: response.errors.first }, 400)
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
            if service.execute(list).error?
              render_api_error!({ error: 'List could not be deleted!' }, 400)
            end
          end
        end

        params :list_creation_params do
          requires :label_id, type: Integer, desc: 'The ID of an existing label'
        end

        params :update_params_ce do
          optional :name, type: String, desc: 'The board name'
          optional :hide_backlog_list, type: Grape::API::Boolean, desc: 'Hide the Open list'
          optional :hide_closed_list, type: Grape::API::Boolean, desc: 'Hide the Closed list'
        end

        params :update_params_ee do
          # Configurable issue boards are not available in CE/EE Core.
          # https://docs.gitlab.com/ee/user/project/issue_board.html#configurable-issue-boards
        end

        params :update_params do
          use :update_params_ce
          use :update_params_ee
        end
      end
    end
  end
end
