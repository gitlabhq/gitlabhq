# frozen_string_literal: true

module Gitlab
  module Auth
    module Otp
      class SessionEnforcer
        OTP_SESSIONS_NAMESPACE = 'session:otp'

        def initialize(key)
          @key = key
        end

        def update_session
          Gitlab::Redis::SharedState.with do |redis|
            redis.setex(key_name, session_expiry_in_seconds, true)
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

        def session_expiry_in_seconds
          Gitlab::CurrentSettings.git_two_factor_session_expiry.minutes.to_i
        end
      end
    end
  end
end
