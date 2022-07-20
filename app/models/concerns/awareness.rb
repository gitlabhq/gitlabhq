# frozen_string_literal: true

module Awareness
  extend ActiveSupport::Concern

  KEY_NAMESPACE = "gitlab:awareness"
  private_constant :KEY_NAMESPACE

  def join(session)
    session.join(self)

    nil
  end

  def leave(session)
    session.leave(self)

    nil
  end

  def session_ids
    with_redis do |redis|
      redis
        .smembers(user_sessions_key)
        # converts session ids from (internal) integer to hex presentation
        .map { |key| key.to_i.to_s(16) }
    end
  end

  private

  def user_sessions_key
    "#{KEY_NAMESPACE}:user:#{id}:sessions"
  end

  def with_redis
    Gitlab::Redis::SharedState.with do |redis|
      yield redis if block_given?
    end
  end
end
