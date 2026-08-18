# frozen_string_literal: true

module Gitlab
  module Metrics
    # Prometheus metrics for namespace (group and project) transfers.
    #
    # Part 9 of https://gitlab.com/gitlab-org/gitlab/-/work_items/586550.
    #
    # Metrics exposed:
    #
    #   gitlab_namespace_transfer_total{namespace_type, result}
    #     Counter incremented for every transfer attempt that reaches a terminal
    #     outcome (success or failure). Transfers are always asynchronous, so
    #     there is no sync/async distinction.
    #
    #   gitlab_namespace_transfer_duration_seconds{namespace_type}
    #     Histogram of wall-clock transfer duration in seconds, observed only
    #     for transfers that complete (success or failure) inside a worker or
    #     service call.
    module Transfers
      DURATION_BUCKETS = [0.5, 1, 5, 10, 30, 60, 120, 300, 600, 1800].freeze

      class << self
        # Increments the transfer counter.
        #
        # @param namespace_type [String] 'group' or 'project'
        # @param result         [String] 'success' or 'failure'
        def count_transfer(namespace_type:, result:)
          transfer_counter.increment(
            namespace_type: namespace_type,
            result: result
          )
        end

        # Observes a transfer duration in the histogram.
        #
        # @param duration_s      [Float]  elapsed seconds
        # @param namespace_type  [String] 'group' or 'project'
        def observe_transfer_duration(duration_s:, namespace_type:)
          transfer_duration_histogram.observe(
            { namespace_type: namespace_type },
            duration_s
          )
        end

        private

        def transfer_counter
          ::Gitlab::Metrics.counter(
            :gitlab_namespace_transfer_total,
            'Total number of namespace (group/project) transfer attempts by outcome'
          )
        end

        def transfer_duration_histogram
          ::Gitlab::Metrics.histogram(
            :gitlab_namespace_transfer_duration_seconds,
            'Duration of namespace (group/project) transfers in seconds',
            {},
            DURATION_BUCKETS
          )
        end
      end
    end
  end
end
