# frozen_string_literal: true

module Gitlab
  module Metrics
    module AggregationEngineSlis
      include Gitlab::Metrics::SliConfig

      puma_enabled!

      SLI_NAME = :aggregation_engine_query
      FEATURE_CATEGORY = 'value_stream_management'
      UNKNOWN_ENGINE = 'unknown'
      DURATION_BUCKETS = [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 20].freeze

      # Every engine starts at the low urgency target until its histogram has enough traffic
      # to derive a per-engine value from, the way GlobalSearchSlis targets are derived.
      DEFAULT_TARGET_S = Gitlab::EndpointAttributes::Config::REQUEST_URGENCIES.fetch(:low).duration
      ENGINE_TARGETS_S = {}.freeze

      class << self
        # Label values are not pre-initialized: engines are labelled by name at runtime, like GitalyClientSlis.
        def initialize_slis!
          Gitlab::Metrics::Sli::Apdex.initialize_sli(SLI_NAME, [])
          Gitlab::Metrics::Sli::ErrorRate.initialize_sli(SLI_NAME, [])
        end

        # Times one aggregation query and records it against the engine's SLI.
        #
        # @param engine [Gitlab::Database::Aggregation::Engine] the engine that built the query
        # @param query_type [Symbol] :data for the page of rows, :count for the total count
        # @return [Object] the block's return value
        def measure(engine:, query_type:)
          labels = { engine: engine_name(engine), query_type: query_type.to_s, feature_category: FEATURE_CATEGORY }
          start = Gitlab::Metrics::System.monotonic_time
          completed = false

          begin
            result = yield
            completed = true
            result
          ensure
            # Also catches Rack::Timeout::RequestTimeoutException, an Exception rather than a
            # StandardError, so a query killed at the request timeout still counts as an error.
            record(labels, Gitlab::Metrics::System.monotonic_time - start, !completed)
          end
        end

        private

        def record(labels, duration_s, error)
          duration_histogram.observe(labels, duration_s)
          Gitlab::Metrics::Sli::ErrorRate[SLI_NAME].increment(labels: labels, error: error)

          return if error

          # Strict like the rails_request apdex, so the same request is not graded two ways at the target.
          Gitlab::Metrics::Sli::Apdex[SLI_NAME].increment(
            labels: labels,
            success: duration_s < ENGINE_TARGETS_S.fetch(labels[:engine], DEFAULT_TARGET_S)
          )
        end

        # Engines built with Engine.build are anonymous classes, whose names would each become a new label value.
        def engine_name(engine)
          name = engine.class.to_s

          name.start_with?('#<') ? UNKNOWN_ENGINE : name.demodulize.underscore
        end

        def duration_histogram
          Gitlab::Metrics.histogram(
            :gitlab_aggregation_engine_query_duration_seconds,
            'Duration of analytics aggregation engine queries',
            {},
            DURATION_BUCKETS
          )
        end
      end
    end
  end
end
