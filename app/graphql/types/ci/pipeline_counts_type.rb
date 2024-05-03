# frozen_string_literal: true

module Types
  module Ci
    class PipelineCountsType < BaseObject
      graphql_name 'PipelineCounts'
      description "Represents pipeline counts for the project"

      authorize :read_pipeline

      (::Types::Ci::PipelineScopeEnum.values.keys - %w[BRANCHES TAGS]).each do |scope|
        field scope.downcase,
          GraphQL::Types::Int,
          null: true,
          description: "Number of pipelines with scope #{scope} for the project"
      end

      field :all,
        GraphQL::Types::Int,
        null: true,
        description: 'Total number of pipelines for the project.'
    end
  end
end
