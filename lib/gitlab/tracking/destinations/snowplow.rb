# frozen_string_literal: true

require 'snowplow-tracker'

module Gitlab
  module Tracking
    module Destinations
      class Snowplow
        SNOWPLOW_NAMESPACE = 'gl'
        DEDICATED_APP_ID = 'gitlab_dedicated'
        SELF_MANAGED_APP_ID = 'gitlab_sm'

        delegate :hostname, :uri, :protocol, to: :@destination_configuration

        attr_reader :destination_configuration

        def initialize(destination_configuration = DestinationConfiguration.snowplow_configuration)
          @destination_configuration = destination_configuration
          @event_eligibility_checker = Gitlab::Tracking::EventEligibilityChecker.new
        end

        def event(category, action, label: nil, property: nil, value: nil, context: nil)
          return unless @event_eligibility_checker.eligible?(action)

          tracker.track_struct_event(
            category: category,
            action: action,
            label: label,
            property: property,
            value: value,
            context: context,
            tstamp: (Time.now.to_f * 1000).to_i
          )
          increment_total_events_counter
        end

        def emit_event_payload(payload)
          # Using #input as the tracker doesn't have an option to track using a json object
          # https://snowplow.github.io/snowplow-ruby-tracker/SnowplowTracker/Emitter.html#input-instance_method
          emitter.input(payload)
        end

        def frontend_client_options(group)
          if Gitlab::CurrentSettings.snowplow_enabled?
            snowplow_options(group)
          else
            product_usage_events_options
          end
        end

        def app_id
          if Gitlab::CurrentSettings.snowplow_enabled?
            Gitlab::CurrentSettings.snowplow_app_id
          else
            product_usage_event_app_id
          end
        end

        private

        def snowplow_options(group)
          additional_features = Feature.enabled?(:additional_snowplow_tracking, group, type: :ops)

          # Using camel case as these keys will be used only in JavaScript
          {
            namespace: SNOWPLOW_NAMESPACE,
            hostname: hostname,
            cookieDomain: cookie_domain,
            appId: app_id,
            formTracking: additional_features,
            linkClickTracking: additional_features
          }
        end

        def product_usage_events_options
          # Using camel case as these keys will be used only in JavaScript
          {
            namespace: SNOWPLOW_NAMESPACE,
            hostname: Gitlab.host_with_port,
            postPath: Rails.application.routes.url_helpers.event_forwarding_path,
            forceSecureTracker: Gitlab.config.gitlab.https,
            appId: app_id
          }
        end

        def product_usage_event_app_id
          app_id = if ::Gitlab::CurrentSettings.gitlab_dedicated_instance?
                     DEDICATED_APP_ID
                   else
                     SELF_MANAGED_APP_ID
                   end

          Gitlab::Tracking::Destinations::DestinationConfiguration.non_production_environment? ? "#{app_id}_staging" : app_id
        end

        def disable_product_usage_event_logging?
          Gitlab::Utils.to_boolean(ENV['GITLAB_DISABLE_PRODUCT_USAGE_EVENT_LOGGING'], default: false)
        end

        def cookie_domain
          Gitlab::CurrentSettings.snowplow_cookie_domain
        end

        def tracker
          @tracker ||= SnowplowTracker::Tracker.new(
            emitters: [emitter],
            subject: SnowplowTracker::Subject.new,
            namespace: SNOWPLOW_NAMESPACE,
            app_id: app_id
          )
        end

        def emitter
          @emitter ||= emitter_class.new(
            endpoint: hostname,
            options: emitter_options
          )
        end

        def emitter_class
          # Use test emitter in test environment to prevent HTTP requests
          return SnowplowTestEmitter if Rails.env.test?

          # snowplow_enabled? is true for gitlab.com and customers that configured their own Snowplow collector
          # In both bases we do not want to log the events being sent as the instance is controlled by the same company
          # controlling the Snowplow collector.
          return SnowplowTracker::AsyncEmitter if Gitlab::CurrentSettings.snowplow_enabled?
          return SnowplowTracker::AsyncEmitter if disable_product_usage_event_logging?

          ::Gitlab::Tracking::SnowplowLoggingEmitter
        end

        def emitter_options
          options = {
            protocol: protocol,
            on_success: method(:increment_successful_events_emissions),
            on_failure: method(:failure_callback),
            method: 'post',
            buffer_size: 1
          }

          return options if Feature.disabled?(:track_struct_event_logger, Feature.current_request)

          options.merge(logger: Gitlab::AppLogger)
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
        end

        def increment_successful_events_emissions(value)
          Gitlab::Metrics.counter(
            :gitlab_snowplow_successful_events_total,
            'Number of successful Snowplow events emissions'
          ).increment({}, value.to_i)
        end

        def increment_total_events_counter
          Gitlab::Metrics.counter(
            :gitlab_snowplow_events_total,
            'Number of Snowplow events'
          ).increment
        end

        def log_failures(failures)
          failures.each do |failure|
            Gitlab::AppLogger.error("#{failure['se_ca']} #{failure['se_ac']} failed to be reported to collector at #{hostname}")
          end
        end
      end
    end
  end
end
