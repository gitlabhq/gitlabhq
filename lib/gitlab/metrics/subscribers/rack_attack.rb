# frozen_string_literal: true

module Gitlab
  module Metrics
    module Subscribers
      # - Adds logging for all Rack Attack blocks and throttling events.
      # - Instrument the cache operations of RackAttack to use in structured
      # logs. Two fields are exposed:
      #   + rack_attack_redis_count: the number of redis calls triggered by
      #   RackAttack in a request.
      #   + rack_attack_redis_duration_s: the total duration of all redis calls
      #   triggered by RackAttack in a request.
      class RackAttack < ActiveSupport::Subscriber
        attach_to 'rack_attack'

        INSTRUMENTATION_STORE_KEY = :rack_attack_instrumentation

        THROTTLES_WITH_USER_INFORMATION = [
          :throttle_authenticated_api,
          :throttle_authenticated_web,
          :throttle_authenticated_protected_paths_api,
          :throttle_authenticated_protected_paths_web,
          :throttle_authenticated_packages_api
        ].freeze

        PAYLOAD_KEYS = [
          :rack_attack_redis_count,
          :rack_attack_redis_duration_s
        ].freeze

        def self.payload
          Gitlab::SafeRequestStore[INSTRUMENTATION_STORE_KEY] ||= {
            rack_attack_redis_count: 0,
            rack_attack_redis_duration_s: 0.0
          }
        end

        def redis(event)
          self.class.payload[:rack_attack_redis_count] += 1
          self.class.payload[:rack_attack_redis_duration_s] += event.duration.to_f / 1000
        end

        def safelist(event)
          req = event.payload[:request]
          Gitlab::Instrumentation::Throttle.safelist = req.env['rack.attack.matched']
        end

        def throttle(event)
          log_into_auth_logger(event)
        end

        def blocklist(event)
          log_into_auth_logger(event)
        end

        def track(event)
          log_into_auth_logger(event)
        end

        private

        def log_into_auth_logger(event)
          req = event.payload[:request]
          rack_attack_info = {
            message: 'Rack_Attack',
            env: req.env['rack.attack.match_type'],
            remote_ip: req.ip,
            request_method: req.request_method,
            path: req.fullpath,
            matched: req.env['rack.attack.matched']
          }

          if THROTTLES_WITH_USER_INFORMATION.include? req.env['rack.attack.matched'].to_sym
            user_id = req.env['rack.attack.match_discriminator']
            user = User.find_by(id: user_id) # rubocop:disable CodeReuse/ActiveRecord

            rack_attack_info[:user_id] = user_id
            rack_attack_info['meta.user'] = user.username unless user.nil?
          end

          Gitlab::InstrumentationHelper.add_instrumentation_data(rack_attack_info)

          logger.error(rack_attack_info)
        end

        def logger
          Gitlab::AuthLogger
        end
      end
    end
  end
end
