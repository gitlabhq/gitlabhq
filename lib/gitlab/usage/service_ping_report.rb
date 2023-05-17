# frozen_string_literal: true

module Gitlab
  module Usage
    class ServicePingReport
      CACHE_KEY = 'usage_data'

      class << self
        def for(output:, cached: false)
          case output.to_sym
          when :all_metrics_values
            Rails.cache.fetch(CACHE_KEY, force: !cached, expires_in: 2.weeks) do
              with_instrumentation_classes(Gitlab::UsageData.data, :with_value)
            end
          when :metrics_queries
            with_instrumentation_classes(metrics_queries, :with_instrumentation)
          when :non_sql_metrics_values
            with_instrumentation_classes(non_sql_metrics_values, :with_instrumentation)
          end
        end

        private

        def with_instrumentation_classes(old_payload, output_method)
          instrumented_metrics_key_paths = Gitlab::Usage::ServicePing::PayloadKeysProcessor.new(old_payload).missing_instrumented_metrics_key_paths

          instrumented_payload = Gitlab::Usage::ServicePing::InstrumentedPayload.new(instrumented_metrics_key_paths, output_method).build

          old_payload.with_indifferent_access.deep_merge(instrumented_payload)
        end

        def metrics_queries
          Gitlab::UsageDataQueries.data
        end

        def non_sql_metrics_values
          Gitlab::UsageDataNonSqlMetrics.data
        end
      end
    end
  end
end
