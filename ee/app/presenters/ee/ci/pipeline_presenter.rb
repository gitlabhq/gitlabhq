module EE
  module Ci
    module PipelinePresenter
      FAILURE_REASONS = {
        activity_limit_exceeded: 'Pipeline activity limit exceeded!',
        size_limit_exceeded: 'Pipeline size limit exceeded!'
      }

      def failure_reason
        return unless pipeline.failure_reason?

        FAILURE_REASONS[pipeline.failure_reason.to_sym] ||
          pipeline.failure_reason
      end
    end
  end
end
