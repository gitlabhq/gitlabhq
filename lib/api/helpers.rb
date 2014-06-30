module API
  module APIHelpers
    PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
    PRIVATE_TOKEN_PARAM = :private_token
    SUDO_HEADER ="HTTP_SUDO"
    SUDO_PARAM = :sudo

    def current_user
      private_token = (params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]).to_s
      @current_user ||= User.find_by(authentication_token: private_token)

      unless @current_user && Gitlab::UserAccess.allowed?(@current_user)
        return nil
      end

      identifier = sudo_identifier()

      # If the sudo is the current user do nothing
      if (identifier && !(@current_user.id == identifier || @current_user.username == identifier))
        render_api_error!('403 Forbidden: Must be admin to use sudo', 403) unless @current_user.is_admin?
        @current_user = User.by_username_or_id(identifier)
        not_found!("No user id or username for: #{identifier}") if @current_user.nil?
      end

      @current_user
    end

    def sudo_identifier()
      identifier ||= params[SUDO_PARAM] ||= env[SUDO_HEADER]

      # Regex for integers
      if (!!(identifier =~ /^[0-9]+$/))
        identifier.to_i
      else
        identifier
      end
    end

    def user_project
      @project ||= find_project(params[:id])
      @project || not_found!
    end

    def find_project(id)
      project = Project.find_with_namespace(id) || Project.find_by(id: id)

      if project && can?(current_user, :read_project, project)
        project
      else
        nil
      end
    end

    def paginate(relation)
      per_page  = params[:per_page].to_i
      paginated = relation.page(params[:page]).per(per_page)
      add_pagination_headers(paginated, per_page)

      paginated
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

    def authorize_push_project
      authorize! :push_code, user_project
    end

    def authorize_admin_project
      authorize! :admin_project, user_project
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
        if params[key].present? or (params.has_key?(key) and params[key] == false)
          attrs[key] = params[key]
        end
      end

      ActionController::Parameters.new(attrs).permit!
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

    def add_pagination_headers(paginated, per_page)
      request_url = request.url.split('?').first

      links = []
      links << %(<#{request_url}?page=#{paginated.current_page - 1}&per_page=#{per_page}>; rel="prev") unless paginated.first_page?
      links << %(<#{request_url}?page=#{paginated.current_page + 1}&per_page=#{per_page}>; rel="next") unless paginated.last_page?
      links << %(<#{request_url}?page=1&per_page=#{per_page}>; rel="first")
      links << %(<#{request_url}?page=#{paginated.total_pages}&per_page=#{per_page}>; rel="last")

      header 'Link', links.join(', ')
    end

    def abilities
      @abilities ||= begin
                       abilities = Six.new
                       abilities << Ability
                       abilities
                     end
    end
  end
end
