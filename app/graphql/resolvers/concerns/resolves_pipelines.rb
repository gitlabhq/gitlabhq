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
             description: "Filter pipelines by their source. Will be ignored if `dast_view_scans` feature flag is disabled."
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
    params.delete(:source) unless Feature.enabled?(:dast_view_scans, project, default_enabled: :yaml)

    Ci::PipelinesFinder.new(project, context[:current_user], params).execute
  end
end
