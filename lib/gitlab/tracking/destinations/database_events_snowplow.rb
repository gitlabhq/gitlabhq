# frozen_string_literal: true

module Gitlab
  module Tracking
    module Destinations
      class DatabaseEventsSnowplow < Snowplow
        extend ::Gitlab::Utils::Override

        HOSTNAME = 'localhost:9091'

        override :enabled?
        # database events are only collected for SaaS instance
        def enabled?
          ::Gitlab.dev_or_test_env? || ::Gitlab.com?
        end

        override :hostname
        def hostname
          HOSTNAME
        end

        private

        override :increment_failed_events_emissions
        def increment_failed_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_db_events_snowplow_failed_events_total,
            'Number of failed Snowplow events emissions'
          ).increment({}, value.to_i)
        end

        override :increment_successful_events_emissions
        def increment_successful_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_db_events_snowplow_successful_events_total,
            'Number of successful Snowplow events emissions'
          ).increment({}, value.to_i)
        end

        override :increment_total_events_counter
        def increment_total_events_counter
          Gitlab::Metrics.counter(
            :gitlab_db_events_snowplow_events_total,
            'Number of Snowplow events'
          ).increment
        end
      end
    end
  end
end
