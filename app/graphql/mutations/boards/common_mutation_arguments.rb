# frozen_string_literal: true

module Mutations
  module Boards
    module CommonMutationArguments
      extend ActiveSupport::Concern

      included do
        argument :name,
          GraphQL::Types::String,
          required: false,
          description: 'Board name.'
        argument :hide_backlog_list,
          GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::BoardType, :hide_backlog_list)
        argument :hide_closed_list,
          GraphQL::Types::Boolean,
          required: false,
          description: copy_field_description(Types::BoardType, :hide_closed_list)
      end
    end
  end
end
