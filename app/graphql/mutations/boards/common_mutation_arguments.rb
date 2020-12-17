# frozen_string_literal: true

module Mutations
  module Boards
    module CommonMutationArguments
      extend ActiveSupport::Concern

      included do
        argument :name,
                 GraphQL::STRING_TYPE,
                 required: false,
                 description: 'The board name.'
        argument :hide_backlog_list,
                 GraphQL::BOOLEAN_TYPE,
                 required: false,
                 description: copy_field_description(Types::BoardType, :hide_backlog_list)
        argument :hide_closed_list,
                 GraphQL::BOOLEAN_TYPE,
                 required: false,
                 description: copy_field_description(Types::BoardType, :hide_closed_list)
      end
    end
  end
end
