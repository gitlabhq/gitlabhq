# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by the ConfigResolver
    module LegacyConfig
      class GroupType < ::Types::Ci::Config::GroupType
        graphql_name 'CiConfigGroup'

        field :jobs, Types::Ci::LegacyConfig::JobType.connection_type, null: true,
          description: 'Jobs in group.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
