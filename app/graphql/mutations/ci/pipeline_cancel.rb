# frozen_string_literal: true

module Mutations
  module Ci
    class PipelineCancel < Base
      graphql_name 'PipelineCancel'

      authorize :update_pipeline

      def resolve(id:)
        pipeline = authorized_find!(id: id)

        if pipeline.cancelable?
          pipeline.cancel_running
          { success: true, errors: [] }
        else
          { success: false, errors: ['Pipeline is not cancelable'] }
        end
      end
    end
  end
end
