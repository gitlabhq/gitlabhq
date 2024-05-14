# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Retry < Base
        graphql_name 'PipelineRetry'

        field :pipeline,
          Types::Ci::PipelineType,
          null: true,
          description: 'Pipeline after mutation.'

        authorize :update_pipeline

        def resolve(id:)
          pipeline = authorized_find!(id: id)
          project = pipeline.project

          service_response = ::Ci::RetryPipelineService.new(project, current_user).execute(pipeline)

          {
            pipeline: pipeline,
            errors: errors_on_object(pipeline) + service_response.errors
          }
        end
      end
    end
  end
end
