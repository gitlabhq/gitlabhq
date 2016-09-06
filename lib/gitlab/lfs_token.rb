module Gitlab
  class LfsToken
    attr_accessor :actor

    TOKEN_LENGTH = 50
    EXPIRY_TIME = 1800

    def initialize(actor)
      set_actor(actor)
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

    def type
      actor.is_a?(User) ? :lfs_token : :lfs_deploy_token
    end

    def actor_name
      actor.is_a?(User) ? actor.username : "lfs-deploy-key-#{actor.id}"
    end

    private

    def redis_key
      "gitlab:lfs_token:#{actor.class.name.underscore}_#{actor.id}" if actor
    end

    def set_actor(actor)
      @actor =
        case actor
        when DeployKey, User
          actor
        when Key
          actor.user
        else
          #
        end
    end
  end
end
