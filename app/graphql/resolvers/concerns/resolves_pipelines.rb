# frozen_string_literal: true

module ResolvesPipelines
  extend ActiveSupport::Concern

  included do
    type Types::Ci::PipelineType.connection_type, null: false
    argument :status,
      Types::Ci::PipelineStatusEnum,
      required: false,
      description: "Filter pipelines by their status."
    argument :scope, ::Types::Ci::PipelineScopeEnum,
      required: false,
      description: 'Filter pipelines by scope.'
    argument :ref,
      GraphQL::Types::String,
      required: false,
      description: "Filter pipelines by the ref they are run for."
    argument :sha,
      GraphQL::Types::String,
      required: false,
      description: "Filter pipelines by the sha of the commit they are run for."
    argument :source,
      GraphQL::Types::String,
      required: false,
      description: "Filter pipelines by their source."

    argument :updated_after, Types::TimeType,
      required: false,
      description: 'Pipelines updated after the date.'
    argument :updated_before, Types::TimeType,
      required: false,
      description: 'Pipelines updated before the date.'

    argument :username,
      GraphQL::Types::String,
      required: false,
      description: "Filter pipelines by the user that triggered the pipeline."
  end

  class_methods do
    def resolver_complexity(args, child_complexity:)
      complexity = super
      complexity += 2 if args[:sha]
      complexity += 2 if args[:ref]

      complexity
    end
  end

  def resolve_pipelines(project, params = {})
    Ci::PipelinesFinder.new(project, context[:current_user], params).execute
  end
end
