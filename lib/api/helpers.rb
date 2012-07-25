module Gitlab
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token])
    end

    def user_project
      if @project ||= current_user.projects.find_by_id(params[:id]) ||
                      current_user.projects.find_by_code(params[:id])
      else
        error!({'message' => '404 Not found'}, 404)
      end

      @project
    end

    def authenticate!
      error!({'message' => '401 Unauthorized'}, 401) unless current_user
    end
  end
end
