# frozen_string_literal: true

module Mutations
  module Boards
    class Update < ::Mutations::BaseMutation
      graphql_name 'UpdateBoard'

      include Mutations::Boards::CommonMutationArguments

      argument :id,
               ::Types::GlobalIDType[::Board],
               required: true,
               description: 'The board global ID.'

      field :board,
            Types::BoardType,
            null: true,
            description: 'The board after mutation.'

      authorize :admin_issue_board

      def resolve(id:, **args)
        board = authorized_find!(id: id)

        ::Boards::UpdateService.new(board.resource_parent, current_user, args).execute(board)

        {
          board: board,
          errors: errors_on_object(board)
        }
      end

      private

      def find_object(id:)
        # TODO: remove this line when the compatibility layer is removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Board].coerce_isolated_input(id)
        GitlabSchema.find_by_gid(id)
      end
    end
  end
end

Mutations::Boards::Update.prepend_mod_with('Mutations::Boards::Update')
