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

    FORBIDDEN_IMPORTING_SCOPES = %w[push delete *].freeze

    ActiveImportError = Class.new(StandardError)

    def execute(authentication_abilities:)
      @authentication_abilities = authentication_abilities

      return error('UNAVAILABLE', status: 404, message: 'registry not enabled') unless registry.enabled

      return error('DENIED', status: 403, message: 'access forbidden') unless has_registry_ability?

      unless scopes.any? || current_user || deploy_token || project
        return error('DENIED', status: 403, message: 'access forbidden')
      end

      if repository_path_push_protected?
        return error('DENIED', status: 403, message: 'Pushing to protected repository path forbidden')
      end

      { token: authorized_token(*scopes).encoded }
    rescue ActiveImportError
      error(
        'DENIED',
        status: 403,
        message: 'Your repository is currently being migrated to a new platform and writes are temporarily disabled. Go to https://gitlab.com/groups/gitlab-org/-/epics/5523 to learn more.'
      )
    end

    def self.full_access_token(*names)
      names_and_actions = names.index_with { %w[*] }
      access_token(names_and_actions)
    end

    def self.import_access_token
      access_token({ 'import' => %w[*] }, 'registry')
    end

    def self.pull_access_token(*names)
      names_and_actions = names.index_with { %w[pull] }
      access_token(names_and_actions)
    end

    def self.pull_nested_repositories_access_token(name)
      name = name.chomp('/')

      access_token({
        name => %w[pull],
        "#{name}/*" => %w[pull]
      })
    end

    def self.push_pull_nested_repositories_access_token(name)
      name = name.chomp('/')

      access_token(
        {
          name => %w[pull push],
          "#{name}/*" => %w[pull]
        },
        override_project_path: name
      )
    end

    def self.access_token(names_and_actions, type = 'repository', override_project_path: nil)
      registry = Gitlab.config.registry
      token = JSONWebToken::RSAToken.new(registry.key)
      token.issuer = registry.issuer
      token.audience = AUDIENCE
      token.expire_time = token_expire_at

      token[:access] = names_and_actions.map do |name, actions|
        {
          type: type,
          name: name,
          actions: actions,
          meta: access_metadata(path: name, override_project_path: override_project_path)
        }.compact
      end

      token.encoded
    end

    def self.token_expire_at
      Time.current + Gitlab::CurrentSettings.container_registry_token_expire_delay.minutes
    end

    def self.access_metadata(project: nil, path: nil, override_project_path: nil)
      return { project_path: override_project_path.downcase } if override_project_path

      # If the project is not given, try to infer it from the provided path
      if project.nil?
        return if path.nil? # If no path is given, return early
        return if path == 'import' # Ignore the special 'import' path

        # If the path ends with '/*', remove it so we can parse the actual repository path
        path = path.chomp('/*')

        # Parse the repository project from the path
        begin
          project = ContainerRegistry::Path.new(path).repository_project
        rescue ContainerRegistry::Path::InvalidRegistryPathError
          # If the path is invalid, gracefully handle the error
          return
        end
      end

      {
        project_path: project&.full_path&.downcase,
        project_id: project&.id,
        root_namespace_id: project&.root_ancestor&.id
      }
    end

    private

    def authorized_token(*accesses)
      JSONWebToken::RSAToken.new(registry.key).tap do |token|
        token.issuer = registry.issuer
        token.audience = params[:service]
        token.subject = current_user.try(:username)
        token.expire_time = self.class.token_expire_at
        token[:auth_type] = params[:auth_type]
        token[:access] = accesses.compact
        token[:user] = user_info_token.encoded
      end
    end

    def user_info_token
      info =
        if current_user
          {
            token_type: params[:auth_type],
            username: current_user.username,
            user_id: current_user.id
          }
        elsif deploy_token
          {
            token_type: params[:auth_type],
            username: deploy_token.username,
            deploy_token_id: deploy_token.id
          }
        end

      JSONWebToken::RSAToken.new(registry.key).tap do |token|
        token[:user_info] = info
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

      raise ActiveImportError if actively_importing?(actions, path)

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
        meta: self.class.access_metadata(project: requested_project)
      }
    end

    def actively_importing?(actions, path)
      return false if FORBIDDEN_IMPORTING_SCOPES.intersection(actions).empty?

      container_repository = ContainerRepository.find_by_path(path)
      return false unless container_repository

      container_repository.migration_importing?
    end

    ##
    # Because we do not have two way communication with registry yet,
    # we create a container repository image resource when push to the
    # registry is successfully authorized.
    #
    def ensure_container_repository!(path, actions)
      return if path.has_repository?
      return unless actions.include?('push')

      ContainerRepository.find_or_create_from_path!(path)
    end

    # Overridden in EE
    def can_access?(requested_project, requested_action)
      return false unless requested_project.container_registry_enabled?

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
        deploy_token.present? &&
        can?(deploy_token, :read_container_image, requested_project)
    end

    def deploy_token_can_push?(requested_project)
      has_authentication_ability?(:create_container_image) &&
        deploy_token.present? &&
        can?(deploy_token, :create_container_image, requested_project)
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

    def repository_path_push_protected?
      return false if Feature.disabled?(:container_registry_protected_containers, project)

      push_scopes = scopes.select { |scope| scope[:actions].include?('push') || scope[:actions].include?('*') }

      push_scopes.any? do |push_scope|
        push_scope_container_registry_path = ContainerRegistry::Path.new(push_scope[:name])

        next unless push_scope_container_registry_path.valid?

        repository_project = push_scope_container_registry_path.repository_project
        current_user_project_authorization_access_level = current_user&.max_member_access_for_project(repository_project.id)

        repository_project.container_registry_protection_rules.for_push_exists?(
          access_level: current_user_project_authorization_access_level,
          repository_path: push_scope_container_registry_path.to_s
        )
      end
    end

    # Overridden in EE
    def extra_info
      {}
    end

    def deploy_token
      params[:deploy_token]
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
