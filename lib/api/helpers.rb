module Gitlab
  module APIHelpers
    PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
    PRIVATE_TOKEN_PARAM = :private_token
    SUDO_HEADER ="HTTP_SUDO"
    SUDO_PARAM = :sudo

    def current_user
      @current_user ||= User.find_by_authentication_token(params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER ])
      identifier = params[SUDO_PARAM] == nil ? env[SUDO_HEADER] : params[SUDO_PARAM]
      # If the sudo is the current user do nothing
      if (identifier && !(@current_user.id == identifier || @current_user.username == identifier))
        render_api_error!('403 Forbidden: Must be admin to use sudo', 403) unless @current_user.is_admin?
        begin

          if (!!(identifier =~ /^[0-9]+$/) || identifier.is_a?( Integer))
            user = User.find_by_id(identifier)
          else
            user = User.find_by_username(identifier)
          end
          if user.nil?
            not_found!("No user id or username for: #{identifier}")
          end
          @current_user = user
        rescue => ex
          not_found!("No user id or username for: #{identifier}")
        end
      end
      @current_user
    end

    def user_project
      @project ||= find_project
      @project || not_found!
    end

    def find_project
      project = Project.find_by_id(params[:id]) || Project.find_with_namespace(params[:id])

      if project && can?(current_user, :read_project, project)
        project
      else
        nil
      end
    end

    def paginate(object)
      object.page(params[:page]).per(params[:per_page].to_i)
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authenticated_as_admin!
      forbidden! unless current_user.is_admin?
    end

    def authorize! action, subject
      unless abilities.allowed?(current_user, action, subject)
        forbidden!
      end
    end

    def can?(object, action, subject)
      abilities.allowed?(object, action, subject)
    end

    # Checks the occurrences of required attributes, each attribute must be present in the params hash
    # or a Bad Request error is invoked.
    #
    # Parameters:
    #   keys (required) - A hash consisting of keys that must be present
    def required_attributes!(keys)
      keys.each do |key|
        bad_request!(key) unless params[key].present?
      end
    end

    def attributes_for_keys(keys)
      attrs = {}
      keys.each do |key|
        attrs[key] = params[key] if params[key].present?
      end
      attrs
    end

    # error helpers

    def forbidden!
      render_api_error!('403 Forbidden', 403)
    end

    def bad_request!(attribute)
      message = ["400 (Bad request)"]
      message << "\"" + attribute.to_s + "\" not given"
      render_api_error!(message.join(' '), 400)
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      render_api_error!(message.join(' '), 404)
    end

    def unauthorized!
      render_api_error!('401 Unauthorized', 401)
    end

    def not_allowed!
      render_api_error!('Method Not Allowed', 405)
    end

    def render_api_error!(message, status)
      error!({'message' => message}, status)
    end

    private

    def abilities
      @abilities ||= begin
        abilities = Six.new
        abilities << Ability
        abilities
      end
    end
  end
end
