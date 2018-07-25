module ResolvesPipelines
  extend ActiveSupport::Concern

  included do
    type [Types::Ci::PipelineType], null: false
    argument :status,
             Types::Ci::PipelineStatusEnum,
             required: false,
             description: "Filter pipelines by their status"
    argument :ref,
             GraphQL::STRING_TYPE,
             required: false,
             description: "Filter pipelines by the ref they are run for"
    argument :sha,
             GraphQL::STRING_TYPE,
             required: false,
             description: "Filter pipelines by the sha of the commit they are run for"
  end

  def resolve_pipelines(project, params = {})
    PipelinesFinder.new(project, context[:current_user], params).execute
  end
end
