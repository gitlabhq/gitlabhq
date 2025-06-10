# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by the ConfigResolver
    module LegacyConfig
      class JobType < ::Types::Ci::Config::JobType
        graphql_name 'CiConfigJob'

        field :needs,
          Types::Ci::Config::NeedType.connection_type,
          null: true,
          description: 'Builds that must complete before the jobs run.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
