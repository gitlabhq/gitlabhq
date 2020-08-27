# frozen_string_literal: true

module Mutations
  module Ci
    class PipelineCancel < BaseMutation
      graphql_name 'PipelineCancel'

      authorize :update_pipeline

      def resolve
        result = ::Ci::CancelUserPipelinesService.new.execute(current_user)

        {
          success: result.success?,
          errors: [result&.message]
        }
      end
    end
  end
end
