# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by the ConfigResolver
    module LegacyConfig
      class StageType < ::Types::Ci::Config::StageType
        graphql_name 'CiConfigStage'

        field :groups, Types::Ci::LegacyConfig::GroupType.connection_type, null: true,
          description: 'Groups of jobs for the stage.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
