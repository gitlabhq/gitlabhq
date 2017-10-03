module EE
  module Ci
    module Pipeline
      EE_FAILURE_REASONS = {
        activity_limit_exceeded: 20,
        size_limit_exceeded: 21
      }.freeze

      def predefined_variables
        result = super
        result << { key: 'CI_PIPELINE_SOURCE', value: source.to_s, public: true }

        result
      end
    end
  end
end
