# frozen_string_literal: true

module Resolvers
  module Ci
    class ProjectPipelineCountsResolver < BaseResolver
      type Types::Ci::PipelineCountsType, null: true

      argument :ref,
        GraphQL::Types::String,
        required: false,
        description: "Filter pipelines by the ref they are run for."

      argument :sha,
        GraphQL::Types::String,
        required: false,
        description: "Filter pipelines by the SHA of the commit they are run for."

      argument :source,
        GraphQL::Types::String,
        required: false,
        description: "Filter pipelines by their source."

      def resolve(**args)
        ::Gitlab::PipelineScopeCounts.new(context[:current_user], object, args)
      end
    end
  end
end
