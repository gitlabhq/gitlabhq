# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class RunnerPlatformType < BaseObject
      graphql_name 'RunnerPlatform'

      field :name, GraphQL::Types::String, null: false,
        description: 'Name slug of the runner platform.'
      field :human_readable_name, GraphQL::Types::String, null: false,
        description: 'Human readable name of the runner platform.'
      field :architectures, Types::Ci::RunnerArchitectureType.connection_type, null: true,
        description: 'Runner architectures supported for the platform.'
    end
  end
end
