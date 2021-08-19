# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class StageType < BaseObject
        graphql_name 'CiConfigStage'

        field :name, GraphQL::Types::String, null: true,
              description: 'Name of the stage.'
        field :groups, Types::Ci::Config::GroupType.connection_type, null: true,
              description: 'Groups of jobs for the stage.'
      end
    end
  end
end
