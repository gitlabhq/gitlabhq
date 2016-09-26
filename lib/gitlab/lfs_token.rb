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

    def generate
      token = Devise.friendly_token(TOKEN_LENGTH)

      Gitlab::Redis.with do |redis|
        redis.set(redis_key, token, ex: EXPIRY_TIME)
      end

      token
    end

    def value
      Gitlab::Redis.with do |redis|
        redis.get(redis_key)
      end
    end

    def user?
      actor.is_a?(User)
    end

    def type
      user? ? :lfs_token : :lfs_deploy_token
    end

    def actor_name
      user? ? actor.username : "lfs+deploy-key-#{actor.id}"
    end

    private

    def redis_key
      "gitlab:lfs_token:#{actor.class.name.underscore}_#{actor.id}" if actor
    end
  end
end
