# frozen_string_literal: true

module Mutations
  module Boards
    class Destroy < ::Mutations::BaseMutation
      graphql_name 'DestroyBoard'

      field :board,
        Types::BoardType,
        null: true,
        description: 'Board after mutation.'
      argument :id,
        ::Types::GlobalIDType[::Board],
        required: true,
        description: 'Global ID of the board to destroy.'

      authorize :admin_issue_board

      def resolve(id:)
        board = authorized_find!(id: id)

        response = ::Boards::DestroyService.new(board.resource_parent, current_user).execute(board)

        {
          board: response.success? ? nil : board,
          errors: response.errors
        }
      end
    end
  end
end
