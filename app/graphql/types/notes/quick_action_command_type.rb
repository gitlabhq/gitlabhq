# frozen_string_literal: true

module Types
  module Notes
    # rubocop:disable Graphql/AuthorizeTypes -- This is a value object; access is gated by the parent noteable field.
    class QuickActionCommandType < BaseObject
      graphql_name 'QuickActionCommand'
      description 'A quick action available to the current user on a noteable.'

      authorize_granular_token skip_reason: :parent_authorizes

      field :name, GraphQL::Types::String,
        null: false,
        description: 'Primary name of the command, rendered as `/name`.'

      field :aliases, [GraphQL::Types::String],
        null: false,
        description: 'Aliases that also invoke the command.'

      field :description, GraphQL::Types::String,
        null: true,
        description: 'Description of what the command does.'

      field :params, [GraphQL::Types::String],
        null: false,
        description: 'Parameter hints shown after the command.'

      field :warning, GraphQL::Types::String,
        null: true,
        description: 'Warning about side effects of running the command.'

      field :icon, GraphQL::Types::String,
        null: true,
        description: 'Name of the icon associated with the command.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
