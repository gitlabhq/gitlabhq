module Projects
  module Settings
    class DeployTokensPresenter < Gitlab::View::Presenter::Simple
      include Enumerable

      presents :deploy_tokens

      def available_scopes
        DeployToken::AVAILABLE_SCOPES
      end

      def length
        deploy_tokens.length
      end

      def scope_description(scope)
        scope_descriptions[scope]
      end

      def each
        deploy_tokens.each do |deploy_token|
          yield deploy_token
        end
      end

      def new_deploy_token
        @new_deploy_token ||= Gitlab::Redis::SharedState.with do |redis|
          token = redis.get(deploy_token_key)
          redis.del(deploy_token_key)
          token
        end
      end

      private

      def scope_descriptions
        {
          'read_repo' => 'Allows read-only access to the repository',
          'read_registry' => 'Allows read-only access to the registry images'
        }
      end

      def deploy_token_key
        DeployToken.redis_shared_state_key(current_user.id)
      end
    end
  end
end
