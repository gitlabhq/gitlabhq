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

          def delete_board
            forbidden! unless board_parent.multiple_issue_boards_available?

            destroy_conditionally!(board) do |board|
              service = ::Boards::DestroyService.new(board_parent, current_user)
              service.execute(board)
            end
          end
        end
      end
    end
  end
end
