# frozen_string_literal: true

module QA
  module Tools
    module Ci
      module Helpers
        # Logger instance
        #
        # @return [Logger]
        def logger
          @logger ||= Gitlab::QA::TestLogger.logger(level: "INFO", source: "CI Tools")
        end
      end
    end
  end
end
