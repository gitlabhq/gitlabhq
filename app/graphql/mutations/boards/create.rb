# frozen_string_literal: true

module Mutations
  module Boards
    class Create < ::Mutations::BaseMutation
      include Mutations::ResolvesResourceParent

      graphql_name 'CreateBoard'

      field :board,
            Types::BoardType,
            null: true,
            description: 'The board after mutation.'

      argument :name,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The board name.'
      argument :assignee_id,
                GraphQL::STRING_TYPE,
                required: false,
                description: 'The ID of the user to be assigned to the board.'
      argument :milestone_id,
               Types::GlobalIDType[Milestone],
               required: false,
               description: 'The ID of the milestone to be assigned to the board.'
      argument :weight,
               GraphQL::BOOLEAN_TYPE,
               required: false,
               description: 'The weight of the board.'
      argument :label_ids,
               [Types::GlobalIDType[Label]],
               required: false,
               description: 'The IDs of labels to be added to the board.'

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
