# frozen_string_literal: true

module Types
  module Notes
    class QuickActionsStatusType < BaseObject
      graphql_name 'QuickActionsStatus'

      authorize :read_note

      field :messages, [GraphQL::Types::String],
        null: true,
        description: 'Response messages from quick actions.'

      field :command_names, [GraphQL::Types::String],
        null: true,
        description: 'Quick action command names.'

      field :commands_only, GraphQL::Types::Boolean,
        null: true,
        description: 'Returns true if only quick action commands were in the note.'

      field :error_messages, [GraphQL::Types::String],
        null: true,
        description: 'Error messages from quick actions that failed to apply.'
    end
  end
end
