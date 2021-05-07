# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class BaseMetric
          include Gitlab::Utils::UsageData

          attr_reader :time_frame

          def initialize(time_frame:)
            @time_frame = time_frame
          end
        end
      end
    end
  end
end
