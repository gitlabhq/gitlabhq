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
      valid_human_user? || valid_group_access_token?(authentication_abilities) || valid_deploy_token?
    end

    def valid_human_user?
      current_user.is_a?(User) && current_user.human?
    end

    def valid_group_access_token?(authentication_abilities)
      current_user&.project_bot? && group_access_token&.active? &&
        (REQUIRED_ABILITIES & authentication_abilities).size == REQUIRED_ABILITIES.size
    end

    def valid_deploy_token?
      deploy_token && deploy_token.valid_for_dependency_proxy?
    end

    def authorized_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['user_id'] = current_user.id if current_user
        token['deploy_token'] = deploy_token.token if deploy_token
        token.expire_time = self.class.token_expire_at
      end
    end

    def group_access_token
      return unless current_user&.project_bot?

      PersonalAccessTokensFinder.new(state: 'active').find_by_token(raw_token)
    end

    def deploy_token
      params[:deploy_token]
    end

    def raw_token
      params[:raw_token]
    end
  end
end
