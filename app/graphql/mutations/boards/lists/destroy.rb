# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Destroy < ::Mutations::BaseMutation
        graphql_name 'DestroyBoardList'

        field :list,
            Types::BoardListType,
            null: true,
            description: 'The list after mutation.'

        argument :list_id, ::Types::GlobalIDType[::List],
                  required: true,
                  loads: Types::BoardListType,
                  description: 'Global ID of the list to destroy. Only label lists are accepted.'

        def resolve(list:)
          raise_resource_not_available_error! unless can_admin_list?(list)

          response = ::Boards::Lists::DestroyService.new(list.board.resource_parent, current_user)
            .execute(list)

          {
            list: response.success? ? nil : list,
            errors: response.errors
          }
        end

        private

        def can_admin_list?(list)
          return false unless list.present?

          Ability.allowed?(current_user, :admin_issue_board_list, list.board)
        end
      end
    end
  end
end
