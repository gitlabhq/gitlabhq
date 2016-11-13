require 'json'

module Gitlab
  class ChatNameToken
    attr_reader :token

    TOKEN_LENGTH = 50
    EXPIRY_TIME = 1800

    def initialize(token = new_token)
      @token = token
    end

    def get
      Gitlab::Redis.with do |redis|
        data = redis.get(redis_key)
        JSON.parse(data, symbolize_names: true) if data
      end
    end

    def store!(params)
      Gitlab::Redis.with do |redis|
        params = params.to_json
        redis.set(redis_key, params, ex: EXPIRY_TIME)
        token
      end
    end

    def delete
      Gitlab::Redis.with do |redis|
        redis.del(redis_key)
      end
    end

    private

    def new_token
      Devise.friendly_token(TOKEN_LENGTH)
    end

    def redis_key
      "gitlab:chat_names:#{token}"
    end
  end
end
