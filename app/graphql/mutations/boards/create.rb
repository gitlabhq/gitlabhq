# frozen_string_literal: true

module Mutations
  module Boards
    class Create < ::Mutations::BaseMutation
      include Mutations::ResolvesResourceParent

      graphql_name 'CreateBoard'

      include Mutations::Boards::CommonMutationArguments

      field :board,
            Types::BoardType,
            null: true,
            description: 'The board after mutation.'

      authorize :admin_board

      def resolve(args)
        board_parent = authorized_resource_parent_find!(args)

        response = ::Boards::CreateService.new(board_parent, current_user, args).execute

        {
          board: response.payload,
          errors: response.errors
        }
      end
    end
  end
end

Mutations::Boards::Create.prepend_if_ee('::EE::Mutations::Boards::Create')
