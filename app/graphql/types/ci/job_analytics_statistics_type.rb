# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsStatisticsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is authorized by the parent resolver
      graphql_name 'CiJobAnalyticsStatistics'
      description 'Statistics for CI/CD job analytics'

      field :count, GraphQL::Types::BigInt,
        null: true,
        description: 'Count of jobs, optionally filtered by status.' do
          argument :status,
            type: ::Types::Ci::AnalyticsJobStatusEnum,
            required: false,
            description: 'Filter job count by status.'
        end

      field :rate, GraphQL::Types::Float,
        null: true,
        description: 'Percentage of jobs, optionally filtered by status.' do
          argument :status,
            type: ::Types::Ci::AnalyticsJobStatusEnum,
            required: false,
            description: 'Filter job rate by status. If not specified, returns 100.0 (representing all jobs).'
        end

      field :duration_statistics, Types::Ci::DurationStatisticsType,
        null: true,
        description: 'Duration statistics for the jobs.'

      def count(status: nil)
        status.nil? || status == :any ? object[:total_count] : object[:"count_#{status}"]
      end

      def duration_statistics
        object
      end

      def rate(status: nil)
        status.nil? || status == :any ? 100.0 : object[:"rate_of_#{status}"]
      end
    end
  end
end
