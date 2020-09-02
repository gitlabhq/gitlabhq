# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class Base < BaseMutation
        include Mutations::ResolvesIssuable

        argument :board_id, ::Types::GlobalIDType[::Board],
                 required: true,
                 description: 'Global ID of the issue board to mutate'

        field :list,
              Types::BoardListType,
              null: true,
              description: 'List of the issue board'

        authorize :admin_list

        private

        def find_object(id:)
          GitlabSchema.object_from_id(id, expected_type: ::Board)
        end
      end
    end
  end
end
