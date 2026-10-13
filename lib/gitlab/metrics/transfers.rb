# frozen_string_literal: true

module Gitlab
  module Metrics
    # Prometheus metrics for namespace (group and project) transfers.
    #
    # Part 9 of https://gitlab.com/gitlab-org/gitlab/-/work_items/586550.
    # Follow-ups: https://gitlab.com/gitlab-org/gitlab/-/work_items/623298.
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
    #
    #   gitlab_namespace_transfer_end_to_end_duration_seconds{namespace_type}
    #     Histogram of seconds from schedule_transfer to a successful
    #     complete_transfer!, including queue wait and Sidekiq deferrals.
    module Transfers
      DURATION_BUCKETS = [0.5, 1, 5, 10, 30, 60, 120, 300, 600, 1800].freeze
      # Deferrals back off up to 30 minutes each, so latency can reach hours.
      END_TO_END_DURATION_BUCKETS = [1, 5, 30, 60, 300, 600, 1800, 3600, 7200, 14400, 43200, 86400].freeze

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

        # A failed attempt clears transfer_scheduled_at and the retry schedules
        # again, so this measures from the most recent schedule.
        #
        # @param scheduled_at   [String, nil] ISO8601 timestamp from state_metadata
        # @param namespace_type [String] 'group' or 'project'
        def observe_end_to_end_transfer_duration(scheduled_at:, namespace_type:)
          return unless scheduled_at

          # Rescue so a malformed timestamp can't fail a transfer that already completed.
          scheduled_time = begin
            Time.zone.parse(scheduled_at)
          rescue ArgumentError, TypeError
            nil
          end

          return unless scheduled_time

          elapsed = (Time.current - scheduled_time).round(6)
          elapsed = 0.0 if elapsed < 0

          end_to_end_transfer_duration_histogram.observe(
            { namespace_type: namespace_type },
            elapsed
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

        def end_to_end_transfer_duration_histogram
          ::Gitlab::Metrics.histogram(
            :gitlab_namespace_transfer_end_to_end_duration_seconds,
            'Seconds from scheduling to completion of namespace (group/project) transfers',
            {},
            END_TO_END_DURATION_BUCKETS
          )
        end
      end
    end
  end
end
