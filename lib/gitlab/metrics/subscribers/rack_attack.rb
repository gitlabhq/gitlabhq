# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # Adds logging and metrics for all Rack Attack blocks and throttling events.
      # Instrument the cache operations of RackAttack to use in structured logs. Two fields are exposed:
      #   - rack_attack_redis_count: the number of redis calls triggered by RackAttack in a request.
      #   - rack_attack_redis_duration_s: the total duration of all redis calls triggered by RackAttack in a request.
      class RackAttack < ActiveSupport::Subscriber
        attach_to 'rack_attack'

        INSTRUMENTATION_STORE_KEY = :rack_attack_instrumentation

        def self.payload
          Gitlab::SafeRequestStore[INSTRUMENTATION_STORE_KEY] ||= {
            rack_attack_redis_count: 0,
            rack_attack_redis_duration_s: 0.0
          }
        end

        # Rubocop requires this be public
        def self.parameter_filter
          @parameter_filter ||= ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
        end

        def safelist(event)
          req = event.payload[:request]
          Gitlab::Instrumentation::Throttle.safelist = req.env['rack.attack.matched']
        end

        def throttle(event)
          log_into_auth_logger(event, status: 429)
          report_metrics(event)
        end

        def blocklist(event)
          log_into_auth_logger(event, status: 403)
          report_metrics(event)
        end

        def track(event)
          log_into_auth_logger(event, status: nil)
          report_metrics(event)
        end

        private

        def parameter_filter
          self.class.parameter_filter
        end

        def log_into_auth_logger(event, status:)
          # req here is a Rack::Attack::Request, inherits from Rack::Request
          # https://rubydoc.info/gems/rack/2.2.9/Rack/Request
          req = event.payload[:request]
          filtered_params = parameter_filter.filter(req.GET)
          req_path = filtered_params.any? ? "#{req.path}?#{filtered_params.to_query}" : req.path

          rack_attack_info = {
            message: 'Rack_Attack',
            env: req.env['rack.attack.match_type'],
            remote_ip: req.ip,
            request_method: req.request_method,
            path: req_path,
            matched: req.env['rack.attack.matched']
          }

          if status
            rack_attack_info[:status] = status
          end

          discriminator = req.env['rack.attack.match_discriminator'].to_s
          discriminator_id = discriminator.split(':').last

          if discriminator.starts_with?('user:')
            user = User.find_by(id: discriminator_id) # rubocop:disable CodeReuse/ActiveRecord
            rack_attack_info[:user_id] = discriminator_id.to_i
            rack_attack_info['meta.user'] = user.username unless user.nil?
          elsif discriminator.starts_with?('deploy_token:')
            rack_attack_info[:deploy_token_id] = discriminator_id.to_i
          end

          Gitlab::InstrumentationHelper.add_instrumentation_data(rack_attack_info)

          logger.error(rack_attack_info)
        end

        def report_metrics(event)
          # req is a Rack::Attack::Request inherited from Rack::Request
          # See https://rubydoc.info/gems/rack/Rack/Request
          req = event.payload[:request]

          type = req.env['rack.attack.match_type'].to_s
          name = req.env['rack.attack.matched'].to_s

          event_counter.increment({ event_type: type, event_name: name })

          return unless type == "throttle"

          data = req.env['rack.attack.match_data']
          return unless data.is_a?(Hash)

          throttle_limit.set({ event_name: name }, data[:limit]) if data[:limit]
          throttle_period.set({ event_name: name }, data[:period]) if data[:period]
        end

        def logger
          Gitlab::AuthLogger
        end

        def event_counter
          @event_counter ||= ::Gitlab::Metrics.counter(
            :gitlab_rack_attack_events_total,
            'The total number of events handled by Rack Attack',
            { event_type: nil, event_name: nil }
          )
        end

        def throttle_limit
          @throttle_limit ||= ::Gitlab::Metrics.gauge(
            :gitlab_rack_attack_throttle_limit,
            'The maximum number of requests that a client can make before Rack Attack throttles them',
            { event_name: nil }
          )
        end

        def throttle_period
          @throttle_period ||= ::Gitlab::Metrics.gauge(
            :gitlab_rack_attack_throttle_period_seconds,
            'The duration over which requests for a client are counted before Rack Attack throttles them',
            { event_name: nil }
          )
        end
      end
    end
  end
end
