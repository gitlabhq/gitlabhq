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

      def scope_descriptions
        {
          'read_repo' => s_('DeployTokens|Allows read-only access to the repository'),
          'read_registry' => s_('DeployTokens|Allows read-only access to the registry images')
        }
      end

      def deploy_token_key
        @deploy_token_key ||= project.deploy_tokens.new.redis_shared_state_key(current_user.id)
      end
    end
  end
end
