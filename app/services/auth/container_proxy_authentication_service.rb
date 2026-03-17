# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- this is an existing class
module Auth
  class ContainerProxyAuthenticationService < BaseService
    AUDIENCE = 'dependency_proxy'
    HMAC_KEY = 'gitlab-dependency-proxy'
    DEFAULT_EXPIRE_TIME = 1.minute
    REQUIRED_CI_ABILITIES = %i[build_read_container_image build_create_container_image].freeze
    REQUIRED_USER_ABILITIES = %i[read_container_image create_container_image].freeze
    REQUIRED_USER_VR_ABILITIES = %i[read_dependency_proxy write_dependency_proxy].freeze

    SERVICE_TYPE_VIRTUAL_REGISTRY = 'virtual_registry'
    SERVICE_TYPE_DEPENDENCY_PROXY = 'dependency_proxy'
    VIRTUAL_REGISTRY_SCOPE_PATTERN = %r{virtual_registries/container/}

    def execute(authentication_abilities:)
      @authentication_abilities = authentication_abilities

      return error('dependency proxy not enabled', 404) unless ::Gitlab.config.dependency_proxy.enabled
      return error('access forbidden', 403) unless valid_user_actor?

      { token: authorized_token.encoded }
    end

    class << self
      include ::Gitlab::Utils::StrongMemoize

      def secret
        OpenSSL::HMAC.hexdigest(
          'sha256',
          ::Gitlab::Encryption::KeyProvider[:db_key_base].encryption_key.secret,
          HMAC_KEY
        )
      end
      strong_memoize_attr :secret

      def token_expire_at
        Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
      end
    end

    private

    attr_reader :authentication_abilities

    def valid_user_actor?
      has_required_abilities? && (!deploy_token || deploy_token.valid_for_dependency_proxy?)
    end

    def has_required_abilities?
      [REQUIRED_CI_ABILITIES, REQUIRED_USER_ABILITIES, REQUIRED_USER_VR_ABILITIES].any? do |required_abilities|
        (required_abilities & authentication_abilities).size == required_abilities.size
      end
    end

    def group_access_token
      PersonalAccessTokensFinder.new(state: 'active').find_by_token(raw_token.to_s)
    end

    def authorized_token
      JSONWebToken::HMACToken.new(self.class.secret).tap do |token|
        token['user_id'] = current_user.id if current_user
        token['deploy_token'] = deploy_token.token if deploy_token
        token['personal_access_token'] = raw_token if personal_access_token_user?
        token['group_access_token'] = raw_token if group_access_token_user?
        token['service_type'] = detect_service_type if scopes.present?
        token.expire_time = self.class.token_expire_at
      end
    end

    def detect_service_type
      return SERVICE_TYPE_VIRTUAL_REGISTRY if scopes.any? { |scope| scope.match?(VIRTUAL_REGISTRY_SCOPE_PATTERN) }

      SERVICE_TYPE_DEPENDENCY_PROXY
    end

    def scopes
      params[:scopes] || []
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
# rubocop:enable Gitlab/BoundedContexts
