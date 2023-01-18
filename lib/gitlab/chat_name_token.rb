# frozen_string_literal: true

require 'json'

module Gitlab
  class ChatNameToken
    attr_reader :token

    TOKEN_LENGTH = 50
    EXPIRY_TIME = 10.minutes

    def initialize(token = new_token)
      @token = token
    end

    def get
      Gitlab::Redis::SharedState.with do |redis|
        data = redis.get(redis_shared_state_key)
        Gitlab::Json.parse(data, symbolize_names: true) if data
      end
    end

    def store!(params)
      Gitlab::Redis::SharedState.with do |redis|
        params = params.to_json
        redis.set(redis_shared_state_key, params, ex: EXPIRY_TIME)
        token
      end
    end

    def delete
      Gitlab::Redis::SharedState.with do |redis|
        redis.del(redis_shared_state_key)
      end
    end

    private

    def new_token
      Devise.friendly_token(TOKEN_LENGTH)
    end

    def redis_shared_state_key
      "gitlab:chat_names:#{token}"
    end
  end
end
