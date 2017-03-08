module Gitlab
  class LfsToken
    attr_accessor :actor

    TOKEN_LENGTH = 50
    EXPIRY_TIME = 1800

    def initialize(actor)
      @actor =
        case actor
        when DeployKey, User
          actor
        when Key
          actor.user
        else
          raise 'Bad Actor'
        end
    end

    def token
      Gitlab::Redis.with do |redis|
        token = redis.get(redis_key)

        if token
          redis.expire(redis_key, EXPIRY_TIME)
        else
          token = Devise.friendly_token(TOKEN_LENGTH)
          redis.set(redis_key, token, ex: EXPIRY_TIME)
        end

        token
      end
    end

    def user?
      actor.is_a?(User)
    end

    def type
      actor.is_a?(User) ? :lfs_token : :lfs_deploy_token
    end

    def actor_name
      actor.is_a?(User) ? actor.username : "lfs+deploy-key-#{actor.id}"
    end

    private

    def redis_key
      "gitlab:lfs_token:#{actor.class.name.underscore}_#{actor.id}" if actor
    end
  end
end
