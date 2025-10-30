# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Cancel < Base
        graphql_name 'PipelineCancel'

        field :pipeline,
          Types::Ci::PipelineType,
          null: true,
          description: 'Pipeline after mutation.'

        authorize :cancel_pipeline

        def resolve(id:)
          pipeline = authorized_find!(id: id)

          result = ::Ci::CancelPipelineService.new(pipeline: pipeline, current_user: current_user).execute

          if result.success?
            {
              pipeline: pipeline,
              success: true,
              errors: []
            }
          else
            {
              pipeline: pipeline,
              success: false,
              errors: [result.message]
            }
          end
        end
      end
    end
  end
end
