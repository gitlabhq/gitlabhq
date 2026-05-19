# frozen_string_literal: true

module Gitlab
  module Tracking
    module Helpers
      module SnowplowEventMetricLogger
        extend ::Gitlab::Utils::Override
        # Helper methods for incrementing metric count when an event is sent

        def increment_successful_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_snowplow_successful_events_total,
            'Number of successful Snowplow events emissions'
          ).increment({}, value.to_i)
        rescue StandardError => e
          Gitlab::AppLogger.warn("Failed to increment Snowplow successful events metrics: #{e.message}")
        end

        def failure_callback(success_count, failures)
          increment_successful_events_emissions(success_count)
          increment_failed_events_emissions(failures.size)
          log_failures(failures)
        end

        def increment_failed_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_snowplow_failed_events_total,
            'Number of failed Snowplow events emissions'
          ).increment({}, value.to_i)
        rescue StandardError => e
          Gitlab::AppLogger.warn("Failed to increment Snowplow failed events metrics: #{e.message}")
        end

        def log_failures(failures)
          failures.each do |failure|
            Gitlab::AppLogger.error(
              "#{failure['se_ca']} #{failure['se_ac']} failed to be reported to collector at #{hostname}"
            )
          end
        end

        private

        def hostname
          Gitlab::Tracking::Destinations::DestinationConfiguration.snowplow_configuration.hostname
        end
      end
    end
  end
end
