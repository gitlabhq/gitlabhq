# frozen_string_literal: true

module Auth
  class DependencyProxyAuthenticationService < BaseService
    AUDIENCE = 'dependency_proxy'
    HMAC_KEY = 'gitlab-dependency-proxy'
    DEFAULT_EXPIRE_TIME = 1.minute
    REQUIRED_ABILITIES = %i[read_container_image create_container_image].freeze

    def execute(authentication_abilities:)
      return error('dependency proxy not enabled', 404) unless ::Gitlab.config.dependency_proxy.enabled
      return error('access forbidden', 403) unless valid_user_actor?(authentication_abilities)

      { token: authorized_token.encoded }
    end

    class << self
      include ::Gitlab::Utils::StrongMemoize

      def secret
        strong_memoize(:secret) do
          OpenSSL::HMAC.hexdigest(
            'sha256',
            ::Settings.attr_encrypted_db_key_base,
            HMAC_KEY
          )
        end
      end

      def token_expire_at
        Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
      end
    end

    private

    def valid_user_actor?(authentication_abilities)
      feature_user = deploy_token&.user || current_user
      if Feature.enabled?(:packages_dependency_proxy_containers_scope_check, feature_user)
        if deploy_token
          deploy_token.valid_for_dependency_proxy?
        elsif current_user&.project_bot?
          group_access_token&.active? && has_required_abilities?(authentication_abilities)
        else
          current_user
        end
      else
        current_user || valid_deploy_token?
      end
    end

    def has_required_abilities?(authentication_abilities)
      (REQUIRED_ABILITIES & authentication_abilities).size == REQUIRED_ABILITIES.size
    end

    def group_access_token
      PersonalAccessTokensFinder.new(state: 'active').find_by_token(raw_token.to_s)
    end

    def valid_deploy_token?
      deploy_token && deploy_token.valid_for_dependency_proxy?
    end

    def authorized_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['user_id'] = current_user.id if current_user
        token['deploy_token'] = deploy_token.token if deploy_token
        token['personal_access_token'] = raw_token if personal_access_token_user?
        token['group_access_token'] = raw_token if group_access_token_user?
        token.expire_time = self.class.token_expire_at
      end
    end

    def deploy_token
      return unless Gitlab::ExternalAuthorization.allow_deploy_tokens_and_deploy_keys?

      params[:deploy_token]
    end

    def raw_token
      params[:raw_token]
    end

    def group_access_token_user?
      raw_token && current_user&.project_bot? && current_user.resource_bot_resource.is_a?(Group)
    end

    def personal_access_token_user?
      raw_token && current_user && (current_user.human? || current_user.service_account?)
    end
  end
end
