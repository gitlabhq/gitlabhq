module Auth
  class ContainerRegistryAuthenticationService < BaseService
    AUDIENCE = 'container_registry'.freeze

    def execute(authentication_abilities:)
      @authentication_abilities = authentication_abilities

      return error('UNAVAILABLE', status: 404, message: 'registry not enabled') unless registry.enabled

      unless scope || current_user || project
        return error('DENIED', status: 403, message: 'access forbidden')
      end

      { token: authorized_token(scope).encoded }
    end

    def self.full_access_token(*names)
      names = names.flatten
      registry = Gitlab.config.registry
      token = JSONWebToken::RSAToken.new(registry.key)
      token.issuer = registry.issuer
      token.audience = AUDIENCE
      token.expire_time = token_expire_at

      token[:access] = names.map do |name|
        { type: 'repository', name: name, actions: %w(*) }
      end

      token.encoded
    end

    def self.token_expire_at
      Time.now + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
    end

    private

    def authorized_token(*accesses)
      JSONWebToken::RSAToken.new(registry.key).tap do |token|
        token.issuer = registry.issuer
        token.audience = params[:service]
        token.subject = current_user.try(:username)
        token.expire_time = self.class.token_expire_at
        token[:access] = accesses.compact
      end
    end

    def scope
      return unless params[:scope]

      @scope ||= process_scope(params[:scope])
    end

    def process_scope(scope)
      type, name, actions = scope.split(':', 3)
      actions = actions.split(',')

      case type
      when 'registry'
        process_registry_access(type, name, actions)
      when 'repository'
        path = ContainerRegistry::Path.new(name)
        process_repository_access(type, path, actions)
      end
    end

    def process_registry_access(type, name, actions)
      return unless current_user&.admin?
      return unless name == 'catalog'
      return unless actions == ['*']

      { type: type, name: name, actions: ['*'] }
    end

    def process_repository_access(type, path, actions)
      return unless path.valid?

      requested_project = path.repository_project

      return unless requested_project

      actions = actions.select do |action|
        can_access?(requested_project, action)
      end

      return unless actions.present?

      # At this point user/build is already authenticated.
      #
      ensure_container_repository!(path, actions)

      { type: type, name: path.to_s, actions: actions }
    end

    ##
    # Because we do not have two way communication with registry yet,
    # we create a container repository image resource when push to the
    # registry is successfuly authorized.
    #
    def ensure_container_repository!(path, actions)
      return if path.has_repository?
      return unless actions.include?('push')

      ContainerRepository.create_from_path!(path)
    end

    def can_access?(requested_project, requested_action)
      return false unless requested_project.container_registry_enabled?

      case requested_action
      when 'pull'
        build_can_pull?(requested_project) || user_can_pull?(requested_project) || deploy_token_can_pull?(requested_project)
      when 'push'
        build_can_push?(requested_project) || user_can_push?(requested_project)
      when '*'
        user_can_admin?(requested_project)
      else
        false
      end
    end

    def registry
      Gitlab.config.registry
    end

    def can_user?(ability, project)
      current_user.is_a?(User) &&
        can?(current_user, ability, project)
    end

    def build_can_pull?(requested_project)
      # Build can:
      # 1. pull from its own project (for ex. a build)
      # 2. read images from dependent projects if creator of build is a team member
      has_authentication_ability?(:build_read_container_image) &&
        (requested_project == project || can_user?(:build_read_container_image, requested_project))
    end

    def user_can_admin?(requested_project)
      has_authentication_ability?(:admin_container_image) &&
        can_user?(:admin_container_image, requested_project)
    end

    def user_can_pull?(requested_project)
      has_authentication_ability?(:read_container_image) &&
        can_user?(:read_container_image, requested_project)
    end
    
    def deploy_token_can_pull?(requested_project)
      has_authentication_ability?(:read_container_image) &&
        current_user.is_a?(DeployToken) &&
        current_user.has_access_to?(requested_project)
    end

    ##
    # We still support legacy pipeline triggers which do not have associated
    # actor. New permissions model and new triggers are always associated with
    # an actor, so this should be improved in 10.0 version of GitLab.
    #
    def build_can_push?(requested_project)
      # Build can push only to the project from which it originates
      has_authentication_ability?(:build_create_container_image) &&
        requested_project == project
    end

    def user_can_push?(requested_project)
      has_authentication_ability?(:create_container_image) &&
        can_user?(current_user, :create_container_image, requested_project)
    end

    def error(code, status:, message: '')
      { errors: [{ code: code, message: message }], http_status: status }
    end

    def has_authentication_ability?(capability)
      @authentication_abilities.to_a.include?(capability)
    end
  end
end
