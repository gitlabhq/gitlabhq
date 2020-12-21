# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class JobType < BaseObject
        graphql_name 'CiConfigJob'

        field :name, GraphQL::STRING_TYPE, null: true,
              description: 'Name of the job'
        field :group_name, GraphQL::STRING_TYPE, null: true,
              description: 'Name of the job group'
        field :stage, GraphQL::STRING_TYPE, null: true,
              description: 'Name of the job stage'
        field :needs, Types::Ci::Config::NeedType.connection_type, null: true,
              description: 'Builds that must complete before the jobs run'
      end
    end
  end
end
