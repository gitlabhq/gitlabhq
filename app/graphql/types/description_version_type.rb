# frozen_string_literal: true

module Types
  class DescriptionVersionType < BaseObject
    graphql_name 'DescriptionVersion'

    authorize :read_issuable

    field :id, ::Types::GlobalIDType[::DescriptionVersion],
      null: false,
      description: 'ID of the description version.'

    field :description, GraphQL::Types::String,
      null: true,
      description: 'Content of the given description version.'
  end
end

Types::DescriptionVersionType.prepend_mod
