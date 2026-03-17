# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module SlowOperationLogger
        extend ActiveSupport::Concern

        SLOW_THRESHOLD_SECONDS = ENV.fetch('CI_SLOW_OPERATION_THRESHOLD_SECONDS', 5).to_i.clamp(1, 60)

        private

        def log_slow_operation(operation_name:, project:, context: {})
          return yield unless slow_operation_logging_enabled?(project)

          start_counters = safe_capture_counters
          start_time = Gitlab::Metrics::System.monotonic_time

          result = yield

          duration = Gitlab::Metrics::System.monotonic_time - start_time

          if duration >= SLOW_THRESHOLD_SECONDS
            end_counters = safe_capture_counters
            safe_emit_log(operation_name, duration, start_counters, end_counters, context)
          end

          result
        end

        def slow_operation_logging_enabled?(project)
          Feature.enabled?(:ci_slow_operation_logger, project, type: :ops)
        end

        # Wrapper methods to ensure logging errors don't affect the main application flow.
        # Since this is observability-only code, we silently rescue any errors.
        def safe_capture_counters
          capture_instrumentation_counters
        rescue StandardError
          {}
        end

        def safe_emit_log(operation_name, duration, start_counters, end_counters, context)
          emit_slow_operation_log(
            operation_name: operation_name,
            duration: duration,
            start_counters: start_counters,
            end_counters: end_counters,
            context: context
          )
        rescue StandardError
        end

        def capture_instrumentation_counters
          {
            **Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_payload,
            gitaly_calls: Gitlab::GitalyClient.get_request_count,
            gitaly_duration_s: Gitlab::GitalyClient.query_time,
            redis_calls: Gitlab::Instrumentation::Redis.get_request_count,
            redis_duration_s: Gitlab::Instrumentation::Redis.query_time
          }
        end

        def emit_slow_operation_log(operation_name:, duration:, start_counters:, end_counters:, context:)
          attributes = {
            message: "CI slow operation alert for #{operation_name}",
            duration_s: duration.round(3),
            gitaly_calls: end_counters[:gitaly_calls] - start_counters[:gitaly_calls],
            gitaly_duration_s: (end_counters[:gitaly_duration_s] - start_counters[:gitaly_duration_s]).round(3),
            redis_calls: end_counters[:redis_calls] - start_counters[:redis_calls],
            redis_duration_s: (end_counters[:redis_duration_s] - start_counters[:redis_duration_s]).round(3)
          }

          Gitlab::Metrics::Subscribers::ActiveRecord.db_counter_payload.each_key do |key|
            attributes[key] = end_counters[key] - start_counters[key]
          end

          Gitlab::AppJsonLogger.info(attributes.merge(context.compact))
        end
      end
    end
  end
end
