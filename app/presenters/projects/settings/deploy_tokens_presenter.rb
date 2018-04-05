module Projects
  module Settings
    class DeployTokensPresenter < Gitlab::View::Presenter::Simple
      include Enumerable

      presents :deploy_tokens

      def length
        deploy_tokens.length
      end

      def each
        deploy_tokens.each do |deploy_token|
          yield deploy_token
        end
      end

      def temporal_token
        @temporal_token ||= Gitlab::Redis::SharedState.with do |redis|
          token = redis.get(deploy_token_key)
          redis.del(deploy_token_key)
          token
        end
      end

      def attributes_deploy_token
        @attributes_deploy_token ||= Gitlab::Redis::SharedState.with do |redis|
          attributes_key = deploy_token_key + ":attributes"
          attributes_content = redis.get(attributes_key) || '{}'
          redis.del(attributes_key)
          JSON.parse(attributes_content)
        end
      end

      private

      def deploy_token_key
        @deploy_token_key ||= DeployToken.redis_shared_state_key(current_user.id)
      end
    end
  end
end
