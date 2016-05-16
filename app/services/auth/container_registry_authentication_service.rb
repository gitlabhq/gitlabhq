module Auth
  class ContainerRegistryAuthenticationService < BaseService
    AUDIENCE = 'container_registry'

    def execute
      return error('not found', 404) unless registry.enabled

      if params[:offline_token]
        return error('forbidden', 403) unless current_user
      else
        return error('forbidden', 403) unless scope
      end

      { token: authorized_token(scope).encoded }
    end

    private

    def authorized_token(*accesses)
      token = JSONWebToken::RSAToken.new(registry.key)
      token.issuer = registry.issuer
      token.audience = params[:service]
      token.subject = current_user.try(:username)
      token[:access] = accesses.compact
      token
    end

    def scope
      return unless params[:scope]

      @scope ||= process_scope(params[:scope])
    end

    def process_scope(scope)
      type, name, actions = scope.split(':', 3)
      actions = actions.split(',')
      return unless type == 'repository'

      process_repository_access(type, name, actions)
    end

    def process_repository_access(type, name, actions)
      requested_project = Project.find_with_namespace(name)
      return unless requested_project

      actions = actions.select do |action|
        can_access?(requested_project, action)
      end

      { type: type, name: name, actions: actions } if actions.present?
    end

    def can_access?(requested_project, requested_action)
      return false unless requested_project.container_registry_enabled?

      case requested_action
      when 'pull'
        requested_project == project || can?(current_user, :read_container_image, requested_project)
      when 'push'
        requested_project == project || can?(current_user, :create_container_image, requested_project)
      else
        false
      end
    end

    def registry
      Gitlab.config.registry
    end
  end
end
