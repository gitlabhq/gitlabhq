module EE
  module API
    module BoardsResponses
      extend ActiveSupport::Concern

      included do
        helpers do
          def create_board
            forbidden! unless board_parent.multiple_issue_boards_available?

            board =
              ::Boards::CreateService.new(board_parent, current_user, { name: params[:name] }).execute

            present board, with: ::API::Entities::Board
          end

          def update_board
            service = ::Boards::UpdateService.new(board_parent, current_user, declared_params)
            service.execute(board)

            if board.valid?
              present board, with: ::API::Entities::Board
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

          params :update_params do
            optional :name, type: String, desc: 'The board name'
            optional :assignee_id, type: Integer, desc: 'The ID of a user to associate with board'
            optional :milestone_id, type: Integer, desc: 'The ID of a milestone to associate with board'
            optional :labels, type: String, desc: 'Comma-separated list of label names'
            optional :weight, type: Integer, desc: 'The weight of the board'
          end
        end
      end
    end
  end
end
