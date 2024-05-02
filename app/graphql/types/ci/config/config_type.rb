# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class ConfigType < BaseObject
        graphql_name 'CiConfig'

        field :errors, [GraphQL::Types::String], null: true,
          description: 'Linting errors.'
        field :includes, [Types::Ci::Config::IncludeType], null: true,
          description: 'List of included files.'
        field :merged_yaml, GraphQL::Types::String, null: true,
          description: 'Merged CI configuration YAML.'
        field :stages, Types::Ci::Config::StageType.connection_type, null: true,
          description: 'Stages of the pipeline.'
        field :status, Types::Ci::Config::StatusEnum, null: true,
          description: 'Status of linting, can be either valid or invalid.'
        field :warnings, [GraphQL::Types::String], null: true,
          description: 'Linting warnings.'
      end
    end
  end
end
