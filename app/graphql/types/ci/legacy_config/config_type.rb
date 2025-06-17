# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by the ConfigResolver
    module LegacyConfig
      class ConfigType < ::Types::Ci::ConfigType
        graphql_name 'CiConfig'

        field :stages, Types::Ci::LegacyConfig::StageType.connection_type, null: true,
          description: 'Stages of the pipeline.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
