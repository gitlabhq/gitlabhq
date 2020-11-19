# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Update < BaseMutation
        graphql_name 'UpdateBoardList'

        argument :list_id, Types::GlobalIDType[List],
                  required: true,
                  loads: Types::BoardListType,
                  description: 'Global ID of the list.'

        argument :position, GraphQL::INT_TYPE,
                  required: false,
                  description: 'Position of list within the board'

        argument :collapsed, GraphQL::BOOLEAN_TYPE,
                  required: false,
                  description: 'Indicates if list is collapsed for this user'

        field :list,
              Types::BoardListType,
              null: true,
              description: 'Mutated list'

        def resolve(list: nil, **args)
          raise_resource_not_available_error! unless can_read_list?(list)
          update_result = update_list(list, args)

          {
            list: update_result[:list],
            errors: list.errors.full_messages
          }
        end

        private

        def update_list(list, args)
          service = ::Boards::Lists::UpdateService.new(list.board, current_user, args)
          service.execute(list)
        end

        def can_read_list?(list)
          return false unless list.present?

          Ability.allowed?(current_user, :read_list, list.board)
        end
      end
    end
  end
end
