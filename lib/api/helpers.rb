module Gitlab
  module APIHelpers
    def current_user
      @current_user ||= User.find_by_authentication_token(params[:private_token])
    end

    def user_project
      @project ||= current_user.projects.find_by_code(params[:id])
    end

    def authenticate!
      error!({'message' => '401 Unauthorized'}, 401) unless current_user
    end
  end
end
