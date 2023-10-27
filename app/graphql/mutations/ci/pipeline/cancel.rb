# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Cancel < Base
        graphql_name 'PipelineCancel'

        authorize :cancel_pipeline

        def resolve(id:)
          pipeline = authorized_find!(id: id)

          result = ::Ci::CancelPipelineService.new(pipeline: pipeline, current_user: current_user).execute

          if result.success?
            { success: true, errors: [] }
          else
            { success: false, errors: [result.message] }
          end
        end
      end
    end
  end
end
