# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Update < BaseUpdate
        graphql_name 'UpdateBoardList'

        argument :list_id, Types::GlobalIDType[List],
                  required: true,
                  loads: Types::BoardListType,
                  description: 'Global ID of the list.'

        field :list,
              Types::BoardListType,
              null: true,
              description: 'Mutated list.'

        private

        def update_list(list, args)
          service = ::Boards::Lists::UpdateService.new(list.board, current_user, args)
          service.execute(list)
        end

        def can_read_list?(list)
          Ability.allowed?(current_user, :read_issue_board_list, list.board)
        end
      end
    end
  end
end
