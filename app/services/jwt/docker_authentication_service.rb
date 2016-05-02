module Jwt
  class DockerAuthenticationService < BaseService
    def execute
      if params[:offline_token]
        return error('forbidden', 403) unless current_user
      end

      { token: token.encoded }
    end

    private

    def token
      token = ::Jwt::RSAToken.new(registry.key)
      token.issuer = registry.issuer
      token.audience = params[:service]
      token.subject = current_user.try(:username)
      token[:access] = access
      token
    end

    def access
      return unless params[:scope]

      scope = process_scope(params[:scope])
      [scope].compact
    end

    def process_scope(scope)
      type, name, actions = scope.split(':', 3)
      actions = actions.split(',')

      case type
      when 'repository'
        process_repository_access(type, name, actions)
      end
    end

    def process_repository_access(type, name, actions)
      current_project = Project.find_with_namespace(name)
      return unless current_project

      actions = actions.select do |action|
        can_access?(current_project, action)
      end

      { type: type, name: name, actions: actions } if actions
    end

    def can_access?(current_project, action)
      case action
      when 'pull'
        current_project == project || can?(current_user, :download_code, current_project)
      when 'push'
        current_project == project || can?(current_user, :push_code, current_project)
      else
        false
      end
    end

    def registry
      Gitlab.config.registry
    end
  end
end
