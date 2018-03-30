module DeployTokens
  class CreateService < BaseService
    REDIS_EXPIRY_TIME = 3.minutes

    def execute
      @project.deploy_tokens.build.tap do |deploy_token|
        deploy_token.attributes = params
        deploy_token.save
        store_deploy_token_info_in_redis(deploy_token)
      end
    end

    private

    def store_deploy_token_info_in_redis(deploy_token)
      deploy_token_key = deploy_token.redis_shared_state_key(current_user.id)

      if deploy_token.persisted?
        store_in_redis(deploy_token_key, deploy_token.token)
      else
        store_deploy_attributes(deploy_token_key, deploy_token)
      end
    end

    def store_deploy_attributes(deploy_token_key, deploy_token)
      attributes = deploy_token.attributes.slice("name", "expires_at")
      deploy_token_attributes_key = deploy_token_key + ":attributes"

      store_in_redis(deploy_token_attributes_key, attributes.to_json)
    end

    def store_in_redis(key, value)
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(key, value, ex: REDIS_EXPIRY_TIME)
      end
    end
  end
end
