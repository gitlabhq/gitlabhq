# frozen_string_literal: true

module Mutations
  module Boards
    class Create < ::Mutations::BaseMutation
      graphql_name 'CreateBoard'

      include Mutations::ResolvesResourceParent
      include Mutations::Boards::CommonMutationArguments

      field :board,
        Types::BoardType,
        null: true,
        description: 'Board after mutation.'

      authorize :admin_issue_board
      authorize_granular_token permissions: :create_issue_board,
        boundaries: [
          { boundary_argument: :project_path, boundary_type: :project },
          { boundary_argument: :group_path, boundary_type: :group }
        ]

      def resolve(args)
        board_parent = authorized_resource_parent_find!(args)

        response = ::Boards::CreateService.new(board_parent, current_user, args).execute

        {
          board: response.success? ? response.payload[:board] : nil,
          errors: response.errors
        }
      end
    end
  end
end

Mutations::Boards::Create.prepend_mod_with('Mutations::Boards::Create')
