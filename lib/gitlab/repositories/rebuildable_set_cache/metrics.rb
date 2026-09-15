# frozen_string_literal: true

module Gitlab
  module Repositories
    class RebuildableSetCache
      class Metrics
        def increment_operation(key:, operation:, status:)
          safely_record(key: key, operation: operation) do
            operation_counter.increment(operation: operation, ref_type: ref_type_for(key), status: status)
          end
        end

        def increment_trust_event(key:, event:)
          safely_record(key: key, event: event) do
            trust_event_counter.increment(ref_type: ref_type_for(key), event: event)
          end
        end

        private

        def safely_record(**context)
          yield
        rescue StandardError => e
          track_metrics_error(e, **context)
        end

        # Use track_exception instead of track_and_raise_for_dev_exception because observability failures must never
        # alter cache behavior or return values. The reporting path is swallowed for the same reason if it also fails.
        def track_metrics_error(error, **context)
          Gitlab::ErrorTracking.track_exception(error, **context)
        rescue StandardError
          nil
        end

        def operation_counter
          @operation_counter ||= Gitlab::Metrics.counter(
            :gitlab_ref_cache_operations_total,
            'Total ref cache operations by operation, ref type, and outcome'
          )
        end

        def trust_event_counter
          @trust_event_counter ||= Gitlab::Metrics.counter(
            :gitlab_ref_cache_trust_events_total,
            'Total ref cache trust lifecycle events'
          )
        end

        def ref_type_for(key)
          RebuildableSetCache::REF_TYPES.fetch(key.to_s, 'unknown')
        end
      end
    end
  end
end
