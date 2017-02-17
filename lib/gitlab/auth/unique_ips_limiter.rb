module Gitlab
  module Auth
    class TooManyIps < StandardError
      attr_reader :user_id, :ip, :unique_ips_count

      def initialize(user_id, ip, unique_ips_count)
        @user_id = user_id
        @ip = ip
        @unique_ips_count = unique_ips_count
      end

      def message
        "User #{user_id} from IP: #{ip} tried logging from too many ips: #{unique_ips_count}"
      end
    end

    class UniqueIpsLimiter
      USER_UNIQUE_IPS_PREFIX = 'user_unique_ips'

      class << self
        def limit_user_id!(user_id)
          if config.unique_ips_limit_enabled
            ip = RequestContext.client_ip
            unique_ips = count_unique_ips(user_id, ip)
            raise TooManyIps.new(user_id, ip, unique_ips) if unique_ips > config.unique_ips_limit_per_user
          end
        end

        def limit_user!(user = nil)
          user = yield if user.nil?
          limit_user_id!(user.id) unless user.nil?
          user
        end

        def config
          Gitlab::CurrentSettings.current_application_settings
        end

        def count_unique_ips(user_id, ip)
          time = Time.now.to_i
          key = "#{USER_UNIQUE_IPS_PREFIX}:#{user_id}"

          Gitlab::Redis.with do |redis|
            unique_ips_count = nil
            redis.multi do |r|
              r.zadd(key, time, ip)
              r.zremrangebyscore(key, 0, time - config.unique_ips_limit_time_window)
              unique_ips_count = r.zcard(key)
            end
            unique_ips_count.value
          end
        end
      end

      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue TooManyIps => ex

          Rails.logger.info ex.message
          [403, { 'Content-Type' => 'text/plain', 'Retry-After' => UniqueIpsLimiter.config.unique_ips_limit_time_window }, ["Too many logins from different IPs\n"]]
        end
      end
    end
  end
end
