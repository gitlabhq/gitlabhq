# frozen_string_literal: true

module Auth
  class ContainerRegistryAuthenticationService < BaseService
    AUDIENCE = 'container_registry'
    REGISTRY_LOGIN_ABILITIES = [
      :read_container_image,
      :create_container_image,
      :destroy_container_image,
      :update_container_image,
      :admin_container_image,
      :build_read_container_image,
      :build_create_container_image,
      :build_destroy_container_image
    ].freeze

    def execute(authentication_abilities:)
      @authentication_abilities = authentication_abilities

      return error('UNAVAILABLE', status: 404, message: 'registry not enabled') unless registry.enabled

      return error('DENIED', status: 403, message: 'access forbidden') unless has_registry_ability?

      unless scopes.any? || current_user || project
        return error('DENIED', status: 403, message: 'access forbidden')
      end

      { token: authorized_token(*scopes).encoded }
    end

    def self.full_access_token(*names)
      access_token(%w(*), names)
    end

    def self.pull_access_token(*names)
      access_token(['pull'], names)
    end

    def self.access_token(actions, names)
      names = names.flatten
      registry = Gitlab.config.registry
      token = JSONWebToken::RSAToken.new(registry.key)
      token.issuer = registry.issuer
      token.audience = AUDIENCE
      token.expire_time = token_expire_at

      token[:access] = names.map do |name|
        { type: 'repository', name: name, actions: actions }
      end

      token.encoded
    end

    def self.token_expire_at
      Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
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

    def scopes
      return [] unless params[:scopes]

      @scopes ||= params[:scopes].map do |scope|
        process_scope(scope)
      end.compact
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

      authorized_actions = actions.select do |action|
        can_access?(requested_project, action)
      end

      log_if_actions_denied(type, requested_project, actions, authorized_actions)

      return unless authorized_actions.present?

      # At this point user/build is already authenticated.
      #
      ensure_container_repository!(path, authorized_actions)

      {
        type: type,
        name: path.to_s,
        actions: authorized_actions,
        migration_eligible: migration_eligible(requested_project, authorized_actions)
      }.compact
    end

    def migration_eligible(project, actions)
      return unless actions.include?('push')
      return unless Feature.enabled?(:container_registry_migration_phase1)

      # The migration process will start by allowing only specific test and gitlab-org projects using the
      # `container_registry_migration_phase1_allow` FF. We'll then move on to a percentage rollout using this same FF.
      # To remove the risk of impacting enterprise customers that rely heavily on the registry during the percentage
      # rollout, we'll add their top-level group/namespace to the `container_registry_migration_phase1_deny` FF. Later,
      # we'll remove them manually from this deny list, and their new repositories will become eligible.
      Feature.disabled?(:container_registry_migration_phase1_deny, project.root_ancestor) &&
        Feature.enabled?(:container_registry_migration_phase1_allow, project)
    end

    ##
    # Because we do not have two way communication with registry yet,
    # we create a container repository image resource when push to the
    # registry is successfully authorized.
    #
    def ensure_container_repository!(path, actions)
      return if path.has_repository?
      return unless actions.include?('push')

      ContainerRepository.create_from_path!(path)
    end

    # Overridden in EE
    def can_access?(requested_project, requested_action)
      return false unless requested_project.container_registry_enabled?
      return false if requested_project.repository_access_level == ::ProjectFeature::DISABLED

      case requested_action
      when 'pull'
        build_can_pull?(requested_project) || user_can_pull?(requested_project) || deploy_token_can_pull?(requested_project)
      when 'push'
        build_can_push?(requested_project) || user_can_push?(requested_project) || deploy_token_can_push?(requested_project)
      when 'delete'
        build_can_delete?(requested_project) || user_can_admin?(requested_project)
      when '*'
        user_can_admin?(requested_project)
      else
        false
      end
    end

    def build_can_delete?(requested_project)
      # Build can delete only from the project from which it originates
      has_authentication_ability?(:build_destroy_container_image) &&
        requested_project == project
    end

    def registry
      Gitlab.config.registry
    end

    def can_user?(ability, project)
      user = current_user.is_a?(User) ? current_user : nil
      can?(user, ability, project)
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
        current_user.has_access_to?(requested_project) &&
        current_user.read_registry?
    end

    def deploy_token_can_push?(requested_project)
      has_authentication_ability?(:create_container_image) &&
        current_user.is_a?(DeployToken) &&
        current_user.has_access_to?(requested_project) &&
        current_user.write_registry?
    end

    ##
    # We still support legacy pipeline triggers which do not have associated
    # actor. New permissions model and new triggers are always associated with
    # an actor. So this should be improved once
    # https://gitlab.com/gitlab-org/gitlab-foss/issues/37452 is resolved.
    #
    def build_can_push?(requested_project)
      # Build can push only to the project from which it originates
      has_authentication_ability?(:build_create_container_image) &&
        requested_project == project
    end

    def user_can_push?(requested_project)
      has_authentication_ability?(:create_container_image) &&
        can_user?(:create_container_image, requested_project)
    end

    def error(code, status:, message: '')
      { errors: [{ code: code, message: message }], http_status: status }
    end

    def has_authentication_ability?(capability)
      @authentication_abilities.to_a.include?(capability)
    end

    def has_registry_ability?
      @authentication_abilities.any? do |ability|
        REGISTRY_LOGIN_ABILITIES.include?(ability)
      end
    end

    # Overridden in EE
    def extra_info
      {}
    end

    def log_if_actions_denied(type, requested_project, requested_actions, authorized_actions)
      return if requested_actions == authorized_actions

      log_info = {
        message: 'Denied container registry permissions',
        scope_type: type,
        requested_project_path: requested_project.full_path,
        requested_actions: requested_actions,
        authorized_actions: authorized_actions,
        username: current_user&.username,
        user_id: current_user&.id,
        project_path: project&.full_path
      }.merge!(extra_info).compact

      Gitlab::AuthLogger.warn(log_info)
    end
  end
end

Auth::ContainerRegistryAuthenticationService.prepend_mod_with('Auth::ContainerRegistryAuthenticationService')
