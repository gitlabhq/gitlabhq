# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes

module Types
  class AccessLevelType < Types::BaseObject
    graphql_name 'AccessLevel'
    description 'Represents the access level of a relationship between a User and object that it is related to'

    field :integer_value, GraphQL::Types::Int, null: true,
          description: 'Integer representation of access level.',
          method: :to_i

    field :string_value, Types::AccessLevelEnum, null: true,
          description: 'String representation of access level.',
          method: :to_i
  end
end
