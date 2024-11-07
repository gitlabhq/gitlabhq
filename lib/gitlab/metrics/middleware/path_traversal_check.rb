# frozen_string_literal: true

module Gitlab
  module Metrics
    module Middleware
      class PathTraversalCheck
        DURATION_APDEX_NAME = :path_traversal_check_request_duration_s
        DURATION_APDEX_FEATURE_CATEGORY = { feature_category: :shared }.freeze
        DURATION_APDEX_SLI_DEFINITION = [
          DURATION_APDEX_NAME,
          [
            DURATION_APDEX_FEATURE_CATEGORY.merge(path_traversal_attempt_rejected: true),
            DURATION_APDEX_FEATURE_CATEGORY.merge(path_traversal_attempt_rejected: false)
          ]
        ].freeze
        DURATION_APDEX_THRESHOLD = 0.001.seconds

        def self.initialize_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(*DURATION_APDEX_SLI_DEFINITION)
        end

        def self.increment(labels:, duration:)
          ::Gitlab::Metrics::Sli::Apdex[DURATION_APDEX_NAME].increment(
            labels: labels.merge(DURATION_APDEX_FEATURE_CATEGORY),
            success: duration <= DURATION_APDEX_THRESHOLD
          )
        end
      end
    end
  end
end
