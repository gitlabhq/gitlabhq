module Gitlab
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token] || env["HTTP_PRIVATE_TOKEN"])
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
