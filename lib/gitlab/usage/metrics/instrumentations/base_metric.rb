# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BaseMetric
          include Gitlab::Utils::UsageData
          include Gitlab::Usage::TimeFrame

          attr_reader :time_frame
          attr_reader :options

          def initialize(time_frame:, options: {})
            @time_frame = time_frame
            @options = options
          end
        end
      end
    end
  end
end
