# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class GroupType < BaseObject
        graphql_name 'CiConfigGroup'

        field :name, GraphQL::Types::String, null: true,
              description: 'Name of the job group.'
        field :jobs, Types::Ci::Config::JobType.connection_type, null: true,
              description: 'Jobs in group.'
        field :size, GraphQL::Types::Int, null: true,
              description: 'Size of the job group.'
      end
    end
  end
end
