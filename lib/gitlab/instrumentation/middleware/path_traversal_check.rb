# frozen_string_literal: true

module Gitlab
  module Instrumentation
    module Middleware
      class PathTraversalCheck
        DURATION_LABEL = :path_traversal_check_duration_s

        def self.duration=(duration)
          return unless Gitlab::SafeRequestStore.active?

          ::Gitlab::SafeRequestStore[DURATION_LABEL] = ::Gitlab::InstrumentationHelper.round_elapsed_time(0, duration)
        end

        def self.duration
          ::Gitlab::SafeRequestStore[DURATION_LABEL] || 0
        end

        def self.payload
          { DURATION_LABEL => duration }
        end
      end
    end
  end
end
