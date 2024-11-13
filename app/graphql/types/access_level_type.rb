# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes

module Types
  class AccessLevelType < Types::BaseObject
    graphql_name 'AccessLevel'
    description 'Represents the access level of a relationship between a User and object that it is related to'

    field :integer_value, GraphQL::Types::Int, null: true,
      description: 'Integer number of the access level.',
      method: :to_i

    field :string_value, Types::AccessLevelEnum, null: true,
      description: 'Enum string of the the access level.',
      method: :to_i

    field :human_access, GraphQL::Types::String, null: true,
      description: 'Human-readable display name for the access level.'

    def human_access
      ::Gitlab::Access.human_access_with_none(object)
    end
  end
end
