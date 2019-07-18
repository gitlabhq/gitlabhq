# frozen_string_literal: true

module Gitlab
  class AnonymousSession
    def initialize(remote_ip, session_id: nil)
      @remote_ip = remote_ip
      @session_id = session_id
    end

    def store_session_id_per_ip
      Gitlab::Redis::SharedState.with do |redis|
        redis.pipelined do
          redis.sadd(session_lookup_name, session_id)
          redis.expire(session_lookup_name, 24.hours)
        end
      end
    end

    def stored_sessions
      Gitlab::Redis::SharedState.with do |redis|
        redis.scard(session_lookup_name)
      end
    end

    def cleanup_session_per_ip_entries
      Gitlab::Redis::SharedState.with do |redis|
        redis.srem(session_lookup_name, session_id)
      end
    end

    private

    attr_reader :remote_ip, :session_id

    def session_lookup_name
      @session_lookup_name ||= "#{Gitlab::Redis::SharedState::IP_SESSIONS_LOOKUP_NAMESPACE}:#{remote_ip}"
    end
  end
end
