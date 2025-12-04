# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsType < BaseObject # rubocop:disable Graphql/AuthorizeTypes -- This is authorized by the resolver
      graphql_name 'CiJobAnalytics'
      description 'CI/CD job analytics data'

      field :name, GraphQL::Types::String,
        null: true,
        description: 'Job name.'

      field :stage,  Types::Ci::StageType,
        null: true,
        description: 'Stage information.'

      field :mean_duration_in_seconds, GraphQL::Types::Float,
        null: true,
        description: 'Average duration of jobs in seconds.'

      field :p95_duration_in_seconds, GraphQL::Types::Float,
        null: true,
        description: '95th percentile duration of jobs in seconds.'

      # rubocop:disable GraphQL/ExtractType -- this type is based on hash data, not an ActiveRecord model
      # So extracting to a separate type makes it difficult for both code and the UX

      field :rate_of_success, GraphQL::Types::Float,
        null: true,
        description: 'Percentage of successful jobs.'

      field :rate_of_failed, GraphQL::Types::Float,
        null: true,
        description: 'Percentage of failed jobs.'

      field :rate_of_canceled, GraphQL::Types::Float,
        null: true,
        description: 'Percentage of canceled jobs.'

      # rubocop:enable GraphQL/ExtractType

      field :statistics, Types::Ci::JobAnalyticsStatisticsType,
        null: true,
        description: 'Statistics for the jobs.'

      def statistics
        object
      end

      def stage
        return if (stage_id = object['stage_id']).nil? || stage_id.to_i == 0

        BatchLoader::GraphQL.for(stage_id).batch do |stage_ids, loader|
          ::Ci::Stage.id_in(stage_ids).preload_pipeline.each do |stage|
            loader.call(stage.id, stage)
          end
        end
      end
    end
  end
end
