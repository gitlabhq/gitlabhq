# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerArchitectureType < BaseObject
      graphql_name 'RunnerArchitecture'

      field :name, GraphQL::STRING_TYPE, null: false,
        description: 'Name of the runner platform architecture.'
      field :download_location, GraphQL::STRING_TYPE, null: false,
        description: 'Download location for the runner for the platform architecture.'
    end
  end
end
