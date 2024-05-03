# frozen_string_literal: true

module Mutations
  module Boards
    class Update < ::Mutations::BaseMutation
      graphql_name 'UpdateBoard'

      include Mutations::Boards::CommonMutationArguments

      argument :id,
        ::Types::GlobalIDType[::Board],
        required: true,
        description: 'Board global ID.'

      field :board,
        Types::BoardType,
        null: true,
        description: 'Board after mutation.'

      authorize :admin_issue_board

      def resolve(id:, **args)
        board = authorized_find!(id: id)

        ::Boards::UpdateService.new(board.resource_parent, current_user, args).execute(board)

        {
          board: board,
          errors: errors_on_object(board)
        }
      end
    end
  end
end

Mutations::Boards::Update.prepend_mod_with('Mutations::Boards::Update')
