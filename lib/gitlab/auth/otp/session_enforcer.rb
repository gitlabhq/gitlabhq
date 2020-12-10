# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      class SessionEnforcer
        OTP_SESSIONS_NAMESPACE = 'session:otp'
        DEFAULT_EXPIRATION = 15.minutes.to_i

        def initialize(key)
          @key = key
        end

        def update_session
          Gitlab::Redis::SharedState.with do |redis|
            redis.setex(key_name, DEFAULT_EXPIRATION, true)
          end
        end

        def access_restricted?
          Gitlab::Redis::SharedState.with do |redis|
            !redis.get(key_name)
          end
        end

        private

        attr_reader :key

        def key_name
          @key_name ||= "#{OTP_SESSIONS_NAMESPACE}:#{key.id}"
        end
      end
    end
  end
end
