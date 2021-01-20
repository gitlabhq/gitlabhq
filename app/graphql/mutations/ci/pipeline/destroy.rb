# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Destroy < Base
        graphql_name 'PipelineDestroy'

        authorize :destroy_pipeline

        def resolve(id:)
          pipeline = authorized_find!(id: id)
          project = pipeline.project

          result = ::Ci::DestroyPipelineService.new(project, current_user).execute(pipeline)
          {
            success: result.success?,
            errors: result.errors
          }
        end
      end
    end
  end
end
