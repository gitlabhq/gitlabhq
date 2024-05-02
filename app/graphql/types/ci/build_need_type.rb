# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # This type is only accessible from CiJob
    class BuildNeedType < BaseObject
      graphql_name 'CiBuildNeed'

      field :id, GraphQL::Types::ID, null: false,
        description: 'ID of the BuildNeed.'
      field :name, GraphQL::Types::String, null: true,
        description: 'Name of the job we need to complete.'
    end
  end
end
