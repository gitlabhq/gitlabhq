module EE
  module Ci
    module Pipeline
      def predefined_variables
        result = super
        result << { key: 'CI_PIPELINE_SOURCE', value: source.to_s, public: true }

        result
      end
    end
  end
end
