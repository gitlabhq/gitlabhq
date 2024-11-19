# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class GroupEnvironmentScopeType < BaseObject
      graphql_name 'CiGroupEnvironmentScope'
      description 'CI/CD environment scope for a group.'

      connection_type_class Types::Ci::GroupEnvironmentScopeConnectionType

      field :name, GraphQL::Types::String,
        null: true,
        description: 'Scope name defininig the enviromnments that can use the variable.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
