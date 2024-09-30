# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Create < BaseCreate
        graphql_name 'BoardListCreate'

        argument :board_id, ::Types::GlobalIDType[::Board],
          required: true,
          description: 'Global ID of the issue board to mutate.'

        argument :position, GraphQL::Types::Int,
          required: false,
          description: 'Position of the list.'

        field :list,
          Types::BoardListType,
          null: true,
          description: 'Issue list in the issue board.'

        authorize :admin_issue_board_list

        private

        def create_list(board, params)
          create_list_service =
            ::Boards::Lists::CreateService.new(board.resource_parent, current_user, params)

          create_list_service.execute(board)
        end
      end
    end
  end
end

Mutations::Boards::Lists::Create.prepend_mod_with('Mutations::Boards::Lists::Create')
