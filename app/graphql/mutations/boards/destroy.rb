# frozen_string_literal: true

module Mutations
  module Boards
    class Destroy < ::Mutations::BaseMutation
      graphql_name 'DestroyBoard'

      field :board,
            Types::BoardType,
            null: true,
            description: 'The board after mutation.'
      argument :id,
                ::Types::GlobalIDType[::Board],
                required: true,
                description: 'The global ID of the board to destroy.'

      authorize :admin_issue_board

      def resolve(id:)
        board = authorized_find!(id: id)

        response = ::Boards::DestroyService.new(board.resource_parent, current_user).execute(board)

        {
          board: response.success? ? nil : board,
          errors: response.errors
        }
      end

      private

      def find_object(id:)
        GitlabSchema.object_from_id(id, expected_type: ::Board)
      end
    end
  end
end
