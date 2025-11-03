# frozen_string_literal: true

module ResolvesPipelines
  extend ActiveSupport::Concern

  REF_TYPE_SCOPE_MAP = {
    'heads' => 'branches',
    'tags' => 'tags'
  }.freeze

  included do
    type Types::Ci::PipelineType.connection_type, null: false

    calls_gitaly!

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
    argument :ref_type, Types::RefTypeEnum,
      required: false,
      description: 'Type of ref.'
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
    extract_scope_from_params!(params)

    pipelines = Ci::PipelinesFinder.new(project, context[:current_user], params).execute

    if %w[branches tags].include?(params[:scope])
      # `branches` and `tags` scopes are ordered in a complex way that is not supported by the keyset pagination.
      # We offset pagination here so we return the correct connection.
      offset_pagination(pipelines)
    else
      pipelines
    end
  end

  private

  def extract_scope_from_params!(params)
    params[:scope] ||= REF_TYPE_SCOPE_MAP[params[:ref_type]]
  end
end
