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
