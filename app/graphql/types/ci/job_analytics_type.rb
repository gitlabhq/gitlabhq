# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is authorized by the resolver
      graphql_name 'CiJobAnalytics'
      description 'CI/CD job analytics data'

      field :name, GraphQL::Types::String,
        null: true,
        description: 'Job name.'

      field :stage_name,  GraphQL::Types::String,
        null: true,
        description: 'Stage name.'

      field :statistics, Types::Ci::JobAnalyticsStatisticsType,
        null: true,
        description: 'Statistics for the jobs.'

      def statistics
        object
      end
    end
  end
end
