# frozen_string_literal: true

module QA
  module Tools
    module Ci
      # Helpers for CI related tasks
      #
      module Helpers
        include Support::API

        # Logger instance
        #
        # @return [Logger]
        def logger
          @logger ||= Gitlab::QA::TestLogger.logger(
            level: Gitlab::QA::Runtime::Env.log_level,
            source: "CI Tools"
          )
        end
      end
    end
  end
end
