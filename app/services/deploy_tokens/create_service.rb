module DeployTokens
  class CreateService < BaseService
    REDIS_EXPIRY_TIME = 3.minutes

    def execute
      @deploy_token = @project.deploy_tokens.create(params)
      store_in_redis if @deploy_token.persisted?

      @deploy_token
    end

    private

    def store_in_redis
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(deploy_token_key, @deploy_token.token, ex: REDIS_EXPIRY_TIME)
      end
    end

    def deploy_token_key
      DeployToken.redis_shared_state_key(current_user.id)
    end
  end
end
