# frozen_string_literal: true

module Mutations
  module Boards
    module Lists
      class BaseUpdate < BaseMutation
        argument :position, GraphQL::Types::Int,
          required: false,
          description: 'Position of list within the board.'

        argument :collapsed, GraphQL::Types::Boolean,
          required: false,
          description: 'Indicates if the list is collapsed for the user.'

        def resolve(list: nil, **args)
          raise_resource_not_available_error! if list.nil? || !can_read_list?(list)

          update_result = update_list(list, args)

          {
            list: update_result.payload[:list],
            errors: update_result.errors
          }
        end

        private

        def update_list(list, args)
          raise NotImplementedError
        end

        def can_read_list?(list)
          raise NotImplementedError
        end
      end
    end
  end
end
