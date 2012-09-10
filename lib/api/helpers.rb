module Gitlab
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token])
    end

    def user_project
      if @project ||= current_user.projects.find_by_id(params[:id]) ||
                      current_user.projects.find_by_code(params[:id])
      else
        not_found!
      end

      @project
    end

    def paginate(object)
      object.page(params[:page]).per(params[:per_page].to_i)
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authorize! action, subject
      unless abilities.allowed?(current_user, action, subject)
        forbidden!
      end
    end

    # error helpers

    def forbidden!
      error!({'message' => '403 Forbidden'}, 403)
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      error!({'message' => message.join(' ')}, 404)
    end

    def unauthorized!
      error!({'message' => '401 Unauthorized'}, 401)
    end

    def not_allowed!
        error!({'message' => 'method not allowed'}, 405)
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
