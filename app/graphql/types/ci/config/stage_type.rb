# frozen_string_literal: true

module Types
  module Ci
    module Config
      # rubocop:disable Graphql/AuthorizeTypes -- Authorization handled in the CiLint mutation
      class StageType < BaseObject
        graphql_name 'CiConfigStageV2'

        field :groups, [Types::Ci::Config::GroupType], null: true,
          description: 'Groups of jobs for the stage.'
        field :name, GraphQL::Types::String, null: true,
          description: 'Name of the stage.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
