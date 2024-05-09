# frozen_string_literal: true

module Gitlab
  module Auth
    class UniqueIpsLimiter
      USER_UNIQUE_IPS_PREFIX = 'user_unique_ips'

      class << self
        def limit_user_id!(user_id)
          if config.unique_ips_limit_enabled
            ip = RequestContext.instance.client_ip
            unique_ips = update_and_return_ips_count(user_id, ip)

            raise TooManyIps.new(user_id, ip, unique_ips) if unique_ips > config.unique_ips_limit_per_user
          end
        end

        def limit_user!(user = nil)
          user ||= yield if block_given?
          limit_user_id!(user.id) unless user.nil?
          user
        end

        def config
          Gitlab::CurrentSettings.current_application_settings
        end

        def update_and_return_ips_count(user_id, ip)
          time = Time.now.utc.to_i
          key = "#{USER_UNIQUE_IPS_PREFIX}:#{user_id}"

          Gitlab::Redis::SharedState.with do |redis|
            redis.multi do |r|
              r.zadd(key, time, ip.to_s)
              r.zremrangebyscore(key, 0, time - config.unique_ips_limit_time_window)
              r.zcard(key)
            end.last
          end
        end
      end
    end
  end
end
